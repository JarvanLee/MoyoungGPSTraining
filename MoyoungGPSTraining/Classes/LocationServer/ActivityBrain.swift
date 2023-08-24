//
// Created by Matt Greenfield on 22/12/15.
// Copyright (c) 2015 Big Paua. All rights reserved.
//

import os.log
import CoreLocation

public class ActivityBrain {

    // settings
    internal static let worstAllowedLocationAccuracy: CLLocationDistance = 300
    internal static let worstAllowedPastSampleRadius: CLLocationDistance = 65 // small enough for slow walking to be detected

    internal static let maximumSampleAge: TimeInterval = 60
    internal static let minimumWakeupConfidenceN = 10
    internal static let minimumConfidenceN = 6
    internal static let minimumRequiredN = 10
    internal static let maximumRequiredN = 60
    internal static let speedSampleN: Int = 4

    public var processHistoricalLocations = false

    public static let highlander = ActivityBrain()

    private let altitudeKalman = KalmanAltitude(qMetresPerSecond: 3)
    private let coordinatesKalman = KalmanCoordinates(qMetresPerSecond: 4)
    
    public lazy var presentSample: ActivityBrainSample = {
        return ActivityBrainSample(mutex: self.samplesMutex)
    }()
    
    private lazy var pastSample: ActivityBrainSample = {
        return ActivityBrainSample(mutex: self.samplesMutex)
    }()
    
    private var pastSampleFrozen = false

    var samplesMutex: UnfairLock = UnfairLock()

}

// MARK: - Public

public extension ActivityBrain {

    static var historicalLocationsBrain: ActivityBrain {
        let brain = ActivityBrain()
        brain.processHistoricalLocations = true
        return brain
    }

    func add(rawLocation location: CLLocation, trustFactor: Double? = nil) {
        presentSample.add(rawLocation: location)

        // feed the kalmans
        if let trustFactor = trustFactor, trustFactor < 1 {
            let accuracyFudge = kCLLocationAccuracyHundredMeters * (1.0 - trustFactor)
            let fudgedLocation = CLLocation(
                coordinate: location.coordinate, altitude: location.altitude,
                horizontalAccuracy: location.horizontalAccuracy + accuracyFudge,
                verticalAccuracy: location.verticalAccuracy + accuracyFudge,
                course: location.course, speed: location.speed,
                timestamp: location.timestamp)
            altitudeKalman.add(location: fudgedLocation)
            coordinatesKalman.add(location: fudgedLocation)

        } else { // nil or 1.0 trustFactor
            altitudeKalman.add(location: location)
            coordinatesKalman.add(location: location)
        }

        // feed the kalmans into the samples
        if let location = kalmanLocation {
            add(filteredLocation: location)
        }
    }

    // MARK: -

    func update() {
        trimThePresentSample()
        presentSample.update()

        if !pastSampleFrozen {
            trimThePastSample()
            pastSample.update()
        }

        // bounded radius should start by being the max of these two
        pastSample.radiusBounded = max(presentSample.nonNegativeHorizontalAccuracy, pastSample.radius)

        // don't let it get so big that normal walking speed can't escape it
        if !pastSampleFrozen {
            pastSample.radiusBounded = min(pastSample.radiusBounded, ActivityBrain.worstAllowedPastSampleRadius)
        }

        // if present is big enough, unfreeze the past
        if pastSampleFrozen && presentSample.n >= dynamicMinimumConfidenceN {
            pastSampleFrozen = false
        }
    }

    // MARK: -

    func freezeTheBrain() {
        pastSampleFrozen = true

        flushThePresentSample()

        // make the kalmans be super eager to accept the first location on wakeup
        altitudeKalman.resetVarianceTo(accuracy: ActivityBrain.worstAllowedLocationAccuracy)
        coordinatesKalman.resetVarianceTo(accuracy: ActivityBrain.worstAllowedLocationAccuracy)
    }

    var horizontalAccuracy: Double {
        return presentSample.nonNegativeHorizontalAccuracy
    }

    // MARK: -

    var kalmanLocation: CLLocation? {
        guard let kalCoord = coordinatesKalman.coordinate else {
            return nil
        }

        guard let rawLoc = coordinatesKalman.unfilteredLocation else {
            return nil
        }

        if let kalAlt = altitudeKalman.altitude, let rawAltLoc = altitudeKalman.unfilteredLocation {
            return CLLocation(coordinate: kalCoord, altitude: kalAlt, horizontalAccuracy: rawLoc.horizontalAccuracy,
                              verticalAccuracy: rawAltLoc.verticalAccuracy, course: rawLoc.course, speed: rawLoc.speed,
                              timestamp: coordinatesKalman.date)

        } else {
            return CLLocation(coordinate: kalCoord, altitude: 0, horizontalAccuracy: rawLoc.horizontalAccuracy,
                              verticalAccuracy: -1, course: rawLoc.course, speed: rawLoc.speed,
                              timestamp: coordinatesKalman.date)
        }
    }

    func resetKalmans() {
        coordinatesKalman.reset()
        altitudeKalman.reset()
    }

    // MARK: -

    var kalmanRequiredN: Double {
        let accuracy = coordinatesKalman.accuracy
        return accuracy > 0 ? accuracy : 30
    }

    // slower speed means higher required (zero speed == max required)
    var speedRequiredN: Double {
        let maxSpeedReq: Double = 10
        let speedReqKmh: Double = 10

        let kmh = presentSample.speed * 3.6

        // negative speed is useless here, so fallback to max required
        guard kmh >= 0 else {
            return maxSpeedReq
        }

        return (maxSpeedReq - (kmh * (maxSpeedReq / speedReqKmh))).clamped(min: 0, max: maxSpeedReq)
    }

    var requiredN: Int {
        let required = Int(kalmanRequiredN + speedRequiredN)
        return required.clamped(min: ActivityBrain.minimumRequiredN, max: ActivityBrain.maximumRequiredN)
    }

    var dynamicMinimumConfidenceN: Int {
        return pastSampleFrozen ? ActivityBrain.minimumWakeupConfidenceN : ActivityBrain.minimumConfidenceN
    }

    // MARK: -

    func spread(_ locations: [CLLocation]) -> TimeInterval {
        if locations.count < 2 {
            return 0
        }
        let firstLocation = locations.first!
        let lastLocation = locations.last!
        return lastLocation.timestamp.timeIntervalSince(firstLocation.timestamp)
    }
}


// MARK: - Internal

internal extension ActivityBrain {

    func add(filteredLocation location: CLLocation) {

        // reject locations that are too old
        if !processHistoricalLocations && location.timestamp.age > ActivityBrain.maximumSampleAge {
            os_log("Rejecting out of date location (age: %@)", type: .info, String(format: "%.0f seconds", location.timestamp.age))
            return
        }
       
        if !location.hasUsableCoordinate {
            os_log("Rejecting location with unusable coordinate", type: .info)
            return
        }

        presentSample.add(filteredLocation: location)
    }

    // MARK: -

    func trimThePresentSample() {
        while true {
            var needsTrim = false

            // don't let the N go bigger than necessary
            if presentSample.n > requiredN {
                needsTrim = true
            }

            // don't let the sample drift into the past
            if !processHistoricalLocations && presentSample.age > ActivityBrain.maximumSampleAge {
                needsTrim = true
            }

            // past and present samples should have similar Ns
            if !pastSampleFrozen && presentSample.n > pastSample.n + 4 {
                needsTrim = true
            }

            guard needsTrim else {
                return
            }

            guard let oldest = presentSample.firstLocation else {
                return
            }

            presentSample.removeLocation(oldest)

            if !pastSampleFrozen {
                pastSample.add(filteredLocation: oldest)
            }
        }
    }

    func trimThePastSample() {

        // past n should be <= present n
        while pastSample.n > 2 && pastSample.n > presentSample.n {
            guard let oldest = pastSample.firstLocation else {
                break
            }
            pastSample.removeLocation(oldest)
        }
    }

    func flushThePresentSample() {
        presentSample.flush()
    }

    func presentIsInsidePast() -> Bool {
        guard let presentCentre = presentSample.location else {
            return false
        }

        guard let pastCentre = pastSample.location else {
            return false
        }

        return presentCentre.distance(from: pastCentre) <= pastSample.radiusBounded
    }
}
