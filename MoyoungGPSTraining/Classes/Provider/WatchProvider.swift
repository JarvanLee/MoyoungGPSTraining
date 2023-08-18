//
//  WatchProvider.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/18.
//

import Foundation

open class WatchProvider: BaseProvider {
    
    let stepLength: Double
    
    public init(traningType: TrainingType, stepLength: Double) {
        self.stepLength = stepLength
        super.init(traningType: traningType)
    }
    
    /// 手动设置心率
    public func setHeartRate(_ heart: Int) {
        self.heartHandler?(heart)
    }
    
    /// 手动设置步数
    public func setSteps(_ steps: Int) {
        self.stepsHandler?(steps)
        if !isGPSRequird {
            let distance = Double(steps) * stepLength * 1.2
            self.distanceHandler?(distance)
        }
    }
    
    /// 手动设置卡路里
    public func setCalorie(_ calorie: Int) {
        self.calorieHandler?(calorie)
    }
}
