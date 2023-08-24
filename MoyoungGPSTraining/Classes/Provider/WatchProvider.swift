//
//  WatchProvider.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/18.
//

import Foundation

open class WatchProvider: BaseProvider {
    
    let stepLength: Double
    
    deinit {
        print("\(Self.self) \(#function)")
    }
    /// 初始化方法
    /// - Parameters:
    ///   - stepLength: 步长
    ///   - locationManager: 定位管理器，如果是室内运动如室内跑步、室内散步等不需要GPS功能的则不传
    public required init(stepLength: Double, isLocationRequird: Bool = false) {
        self.stepLength = stepLength
        super.init(isLocationRequird: isLocationRequird)
    }
    
    /// 手动设置心率
    public override func setHeartRate(_ heart: Int) {
        super.setHeartRate(heart)
        self.heartHandler?(heart)
    }
    
    /// 手动设置步数
    public override func setSteps(_ steps: Int) {
        super.setSteps(steps)
        self.stepsHandler?(steps)
        if !isLocationRequird {
            let distance = Double(steps) * stepLength * 1.2
            self.distanceHandler?(distance)
        }
    }
    
    /// 手动设置卡路里
    public override func setCalorie(_ calorie: Int) {
        super.setCalorie(calorie)
        self.calorieHandler?(calorie)
    }
}
