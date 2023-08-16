//
//  GpsDataProvider.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/9.
//

import CoreLocation
import Foundation

open class GpsProvider: NSObject, RuningDataInterface {
    public var stepsHandler: IntHandler?
    
    public var calorieHandler: IntHandler?
    
    public var heartHandler: IntHandler?
    
    public var locationsHander: LocationsHandler?
    
    public var headingAngleHandler: DoubleHandler?
    
    public var locationSingleHandler: LocationSingleHandler?

    public var distanceHandler: DoubleHandler?
    
    public var speedHandler: DoubleHandler?
    
    public var altitudeListHandler: DoubleListHandler?
    
    let locationManager = GPSTrainingLocationManager()
    var locations: [CLLocation] = []

    let traningType: TrainingType
    
    public init(traningType: TrainingType) {
        self.traningType = traningType
        super.init()
        
        locationManager.locationsUpdateHandler = { [weak self] location in
            guard let `self` = self else { return }
            self.locations.append(location)
            self.syncData()
            self.locationsHander?(self.locations)
            self.altitudeListHandler?(self.locations.map { $0.altitude })
        }
        locationManager.headingAngleUpdateHandler = { [weak self] angle in
            guard let `self` = self else { return }
            self.headingAngleHandler?(angle)
        }
        locationManager.signalAccuracyUpdateHandler = { [weak self] signal in
            guard let `self` = self else { return }
            self.locationSingleHandler?(signal)
        }
    }
    
    public func start() {
        locationManager.startUpdating()
    }
    
    public func pause() {
        locationManager.pauseUpdating()
    }
    
    public func stop() {
        locationManager.stopUpdating()
    }
    
    public func calculateElevation() -> Double {
        var elevation: Double = 0
        
        if locations.count < 2 {
            return elevation
        }
        
        var minLocation: CLLocation?
        var maxLocation: CLLocation?
        
        for i in 1 ..< (locations.count - 1) {
            let last = locations[i - 1]
            let current = locations[i]
            let next = locations[i + 1]
            
            if current.altitude >= last.altitude && current.altitude > next.altitude {
                maxLocation = current
            }
            // 最后一个还是上坡
            if i == locations.count - 2 && current.altitude < next.altitude {
                maxLocation = next
            }
            
            if current.altitude <= last.altitude && current.altitude < next.altitude {
                minLocation = current
            }
            
            // 第一段是下坡
            if i == 1 && current.altitude > last.altitude {
                minLocation = last
            }
            
            if let max = maxLocation, let min = minLocation {
                let d = max.altitude - min.altitude
                if min.altitude < max.altitude && d < 2.0 {
                    elevation += d
                }
                maxLocation = nil
                minLocation = nil
            }
        }
        return elevation
    }
    
    private func syncData() {
        var distance: CLLocationDistance = 0
        if locations.count > 1 {
            var currentLocation: CLLocation? = nil
            for location in locations {
                if currentLocation != nil {
                    distance += location.distance(from: currentLocation!)
                }
                currentLocation = location
            }
        }
        distanceHandler?(distance)
        
        if let location = locations.last, location.speed > 0 {
            speedHandler?(location.speed)
        }
    }
}
