//
//  GpsDataProvider.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/9.
//

import Foundation
import CoreLocation

open class GpsProvider: NSObject, RuningDataInterface {
    public var stepsHandler: IntHandler?
    
    public var calorieHandler: IntHandler?
    
    public var heartHandler: IntHandler?
    
    public var locationsHander: LocationsHandler?
    
    public var headingAngleHandler: DoubleHandler?
    
    public var locationSingleHandler: LocationSingleHandler?

    public var distanceHandler: DoubleHandler?
    
    public var speedHandler: DoubleHandler?
    
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
        return 0
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
        self.distanceHandler?(distance)
        
        if let location = locations.last, location.speed > 0 {
            self.speedHandler?(location.speed)
        }
    }
}

