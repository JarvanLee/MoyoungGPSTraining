//
//  RunnerDelegate.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/12.
//

import CoreLocation
import Foundation

public protocol RunnerDelegate: NSObjectProtocol {
    /// 在运行中每秒调一次
    func runner(_ runner: Runner, didUpdateRun run: Run)

    /// 更新运动状态
    func runner(_ runner: Runner, didUpdateState runState: RunState)
    /// 更新目标达成进度
    func runner(_ runner: Runner, didUpdateGoalProgress progress: Progress)
    /// 更新GPS坐标，有可能没有数据
    func runner(_ runner: Runner, didUpdateLocations locations: [CLLocation])
    /// 更新GPS位置指针角度
    func runner(_ runner: Runner, didUpdateHeadingAngle angle: Double)
    /// 更新GPS信号等级
    func runner(_ runner: Runner, didUpdateSignalLevel level: GPSTrainingLocationSignalRange)
    /// GPS权限回调
    func runner(_ runner: Runner, didChangeAuthorization state: CLAuthorizationStatus)
    /// GPS错误
    func runner(_ runner: Runner, didFailWithError error: Error)
}

public extension RunnerDelegate {
    func runner(_ runner: Runner, didUpdateGoalProgress progress: Progress) {}
    func runner(_ runner: Runner, didUpdateState runState: RunState) {}
    func runner(_ runner: Runner, didUpdateLocations locations: [CLLocation]) {}
    func runner(_ runner: Runner, didUpdateHeadingAngle angle: Double) {}
    func runner(_ runner: Runner, didUpdateSignalLevel level: GPSTrainingLocationSignalRange) {}
    func runner(_ runner: Runner, didChangeAuthorization state: CLAuthorizationStatus) {}
    func runner(_ runner: Runner, didFailWithError error: Error) {}
}
