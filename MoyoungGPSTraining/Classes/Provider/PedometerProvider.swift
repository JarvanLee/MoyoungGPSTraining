//
//  PedometerProvider.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/10.
//

import Foundation
import CoreMotion

open class PedometerProvider: NSObject, RuningDataInterface {
    
    var totalStpe = 0
    var totalDistance = 0.0
    var totalCalorie = 0
    
    var lastPedemeterStep = 0
    var lastPedemeterDistance = 0.0
    var lastPedemeterCalorie = 0
    
    let pedometer = CMPedometer()

    public var stepsHandler: IntHandler?
    
    public var distanceHandler: DoubleHandler?
    
    public var calorieHandler: IntHandler?
    
    public var speedHandler: DoubleHandler?
    
    public var heartHandler: IntHandler?
    
    public func calculateElevation() -> Double {
        return 0
    }
    
    private var isMapRequird = false
    
    public convenience init(isMapRequird: Bool = false) {
        self.init()
        self.isMapRequird = isMapRequird
    }
    
    public func start() {
        if isMapRequird {
            LocationServer.shared.startUpdate()
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
            self.updateData()
        }
    }
    
    public func pause() {
        if isMapRequird {
            LocationServer.shared.pauseUpdate()
        }
        pedometer.stopUpdates()
        
        lastPedemeterStep = totalStpe
        lastPedemeterDistance = totalDistance
        lastPedemeterCalorie = totalCalorie
        
        self.updateData()
    }
    
    public func stop() {
        if isMapRequird {
            LocationServer.shared.stopUpdate()
        }
        pedometer.stopUpdates()
        
        lastPedemeterStep = totalStpe
        lastPedemeterDistance = totalDistance
        lastPedemeterCalorie = totalCalorie
        
        self.updateData()
    }
    
    private func updateData() {
        self.stepsHandler?(self.totalStpe)
        self.distanceHandler?(self.totalDistance)
        self.calorieHandler?(self.totalCalorie)
    }
    
}
