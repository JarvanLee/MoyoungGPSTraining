//
//  PedometerProvider.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/10.
//

import CoreLocation
import CoreMotion
import Foundation

open class PedometerProvider: BaseProvider {

    var pedometerSteps = 0
    var pedometerDistance = 0.0
    var pedometerSpeed = 0.0
    var pedometerCalorie: Int {
        return self.getCalorie(from: self.pedometerDistance)
    }
    
    var lastPedemeterStep = 0
    var lastPedemeterDistance = 0.0
    
    let pedometer = CMPedometer()

    let weight: Double
    
    /// 初始化方法
    /// - Parameters:
    ///   - traningType: 锻炼类型
    ///   - weight: 体重
    public init(traningType: TrainingType, weight: Double) {
        self.weight = weight
        super.init(traningType: traningType)
    }
    
    /// 手动设置心率
    public override func setHeartRate(_ heart: Int) {
        super.setHeartRate(heart)
        self.heartHandler?(heart)
    }
    
    public override func start() {
        super.start()
        self.pedometer.startUpdates(from: Date()) { [weak self] pedometerData, _ in
            guard let `self` = self else { return }
            if let pedometerData = pedometerData {
                let step = Int(truncating: pedometerData.numberOfSteps)
                let distance = pedometerData.distance?.doubleValue ?? 0.0
                self.pedometerSteps = self.lastPedemeterStep + step
                self.pedometerDistance = self.lastPedemeterDistance + distance
                self.pedometerSpeed = pedometerData.currentPace?.doubleValue ?? 0.0
            }
            self.syncPedometerData()
        }
    }
    
    public override func pause() {
        super.pause()
        
        self.pedometer.stopUpdates()
        
        self.lastPedemeterStep = self.pedometerSteps
        self.lastPedemeterDistance = self.pedometerDistance
        
        self.syncPedometerData()
    }
    
    public override func stop() {
        super.stop()
        
        self.pedometer.stopUpdates()
        
        self.lastPedemeterStep = self.pedometerSteps
        self.lastPedemeterDistance = self.pedometerDistance
        
        self.syncPedometerData()
    }
    
    override func syncGPSData() {
        super.syncGPSData()
        
        if isGPSRequird {
            self.calorieHandler?(self.getCalorie(from: self.gpsDistance))
        }
    }
    
    private func syncPedometerData() {
        self.stepsHandler?(self.pedometerSteps)
        if !isGPSRequird {
            self.distanceHandler?(self.pedometerDistance)
            self.calorieHandler?(self.pedometerCalorie)
            self.speedHandler?(self.pedometerSpeed)
        }
    }

    /// 计算卡路里
    /// - Parameter distance: 运动距离
    /// - Returns: 千卡
    ///  体重×运动时间（小时）×指数K
    ///  指数K＝30÷速度（分钟/400米）
    private func getCalorie(from distance: Double) -> Int {
        return lround(self.weight * distance / 800)
    }
}
