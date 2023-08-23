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
    ///  - 单位：米
    public var totalDistance: Double = 0.0
    /// 有效时间
    public var totalValidDuration: TimeInterval = 0
    /// 累计爬升
    ///  - 单位：米
    public var climbingHeight: Double = 0.0
    
    /// 每分钟步数
    public var stepsPerMinute: [Int] = []
    /// 每分钟距离
    ///  - 单位：米
    public var distancePerMinute: [Double] = []
    
    /// 每分钟心率数
    public var heartPerMinute: [Int] = []
    /// 当前心率
    public var currentHeart: Int = 0
    /// 最大心率
    public var maxHeart: Int?
    /// 最小心率
    public var minHeart: Int?
    
    /// 当前配速
    ///  - 单位：秒/米
    public var currentSpeed: Double = 0.0

    /// 平均配速
    ///  - 单位：秒/米
    public var getAverageSpeed: Double {
        guard totalDistance > 0 else {
            return 0
        }
        return totalValidDuration / totalDistance
    }
    
    /// 每公里耗时
    ///  - 单位：秒/公里
    public var timeForKilometer: [TimeInterval] = []
    
    /// 每英里耗时
    ///  - 单位：秒/英里
    public var timeForMile: [TimeInterval] = []
    
    /// 实时配速(根据runner的realTimeInterval间隔计算数据，默认10秒一个)
    /// 如果目标静止，则返回-1
    ///  - 单位：秒/米
    public var realTimeSpeed: [Double] = []
    
    /// 实时海拔(根据runner的realTimeInterval间隔计算数据，默认10秒一个)
    ///  - 单位： 米
    public var realTimeElevation: [Double] = []
}
