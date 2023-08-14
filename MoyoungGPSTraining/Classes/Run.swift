//
//  Run.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/8.
//

import Foundation

open class Run: NSObject {
    
    /// 总步数
    public var totalStep: Int = 0
    /// 总卡路里
    public var totalCalorie: Int = 0
    /// 运动距离
    public var totalDistance: Double = 0.0
    /// 有效时间
    public var totalValidDuration: TimeInterval = 0
    /// 累计爬升
    public var elevation: Double = 0.0
    
    /// 每分钟步数
    public var minSteps: [Int] = []
    /// 每分钟距离
    public var minDistance: [Double] = []
    /// 每分钟心率数
    public var minHeart: [Int] = []
    
    /// 当前配速
    public var currentSpeed: Double = 0.0
    /// 当前心率
    public var currentHeart: Int = 0
    /// 平均配速
    public var getAverageSpeed: Double {
        guard totalDistance > 0 else {
            return 0
        }
        return totalValidDuration / totalDistance
    }
    
    /// 每公里耗时
    public var timeForKilometer: [TimeInterval] = []
}
