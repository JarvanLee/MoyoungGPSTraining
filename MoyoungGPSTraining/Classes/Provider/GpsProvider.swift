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
    
    public var distanceHandler: DoubleHandler?
    
    public var calorieHandler: IntHandler?
    
    public var speedHandler: DoubleHandler?
    
    public var heartHandler: IntHandler?

    public override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: .locationsUpdate, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let `self` = self else { return }
            if let locations = notification.object as? [CLLocation] {
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
    }
    
    public func start() {
        LocationServer.shared.startUpdate()
    }
    
    public func pause() {
        LocationServer.shared.pauseUpdate()
    }
    
    public func stop() {
        LocationServer.shared.stopUpdate()
    }
  
    public func calculateElevation() -> Double {
        return 0
    }
}

