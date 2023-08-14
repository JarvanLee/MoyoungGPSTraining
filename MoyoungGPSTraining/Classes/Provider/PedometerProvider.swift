//
//  PedometerProvider.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/10.
//

import Foundation
import CoreMotion
import CoreLocation

open class PedometerProvider: NSObject, RuningDataInterface {
    
    public var locationsHander: LocationsHandler?
    
    public var headingAngleHandler: DoubleHandler?
    
    public var locationSingleHandler: LocationSingleHandler?
    
    public var stepsHandler: IntHandler?
    
    public var distanceHandler: DoubleHandler?
    
    public var calorieHandler: IntHandler?
    
    public var speedHandler: DoubleHandler?
    
    public var heartHandler: IntHandler?
    
    public func calculateElevation() -> Double {
        return 0
    }
    
    var totalStpe = 0
    var totalDistance = 0.0
    var totalCalorie = 0
    
    var lastPedemeterStep = 0
    var lastPedemeterDistance = 0.0
    var lastPedemeterCalorie = 0
    
    let pedometer = CMPedometer()

    private var isMapRequird = false
    private var locationManager: GPSTrainingLocationManager?
    private var locations: [CLLocation] = []
    
    public convenience init(isMapRequird: Bool = false) {
        self.init()
        self.isMapRequird = isMapRequird
    }
    
    public func start() {
        if isMapRequird {
            if self.locationManager == nil {
                self.locationManager = GPSTrainingLocationManager()
                self.locationManager?.locationsUpdateHandler = { [weak self] location in
                    guard let `self` = self else { return }
                    self.locations.append(location)
                    self.locationsHander?(self.locations)
                }
                self.locationManager?.headingAngleUpdateHandler = { [weak self] angle in
                    guard let `self` = self else { return }
                    self.headingAngleHandler?(angle)
                }
                self.locationManager?.signalAccuracyUpdateHandler = { [weak self] signal in
                    guard let `self` = self else { return }
                    self.locationSingleHandler?(signal)
                }
                self.locationManager?.startUpdating()
            }
            
        }
        pedometer.startUpdates(from: Date()) { [weak self] pedometerData, error in
            guard let `self` = self else { return }
            if let pedometerData = pedometerData {
                let step = Int(truncating: pedometerData.numberOfSteps)
                self.totalStpe = self.lastPedemeterStep + step
                self.totalDistance = self.lastPedemeterDistance + (pedometerData.distance?.doubleValue ?? 0)
                self.totalCalorie = self.lastPedemeterCalorie + Int((Double(step * 4)/1000).rounded())
                self.speedHandler?(pedometerData.currentPace?.doubleValue ?? 0.0)
            }
            self.syncData()
        }
    }
    
    public func pause() {
        self.locationManager?.pauseUpdating()
        pedometer.stopUpdates()
        
        lastPedemeterStep = totalStpe
        lastPedemeterDistance = totalDistance
        lastPedemeterCalorie = totalCalorie
        
        self.syncData()
    }
    
    public func stop() {
        self.locationManager?.stopUpdating()
        self.locationManager = nil
        pedometer.stopUpdates()
        
        lastPedemeterStep = totalStpe
        lastPedemeterDistance = totalDistance
        lastPedemeterCalorie = totalCalorie
        
        self.syncData()
    }
    
    private func syncData() {
        self.stepsHandler?(self.totalStpe)
        self.distanceHandler?(self.totalDistance)
        self.calorieHandler?(self.totalCalorie)
    }
    
}
