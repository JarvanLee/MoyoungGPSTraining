//
//  RunnerDelegate.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/12.
//

import Foundation
import CoreLocation

public protocol RunnerDelegate: NSObjectProtocol {
    
    /// 在运行中每秒调一次
    func runner(_ runner: Runner, didUpdateRun run: Run)
    
    func runner(_ runner: Runner, didUpdateGoalProgress progress: Progress)
    
    func runner(_ runner: Runner, didUpdateLocations locations: [CLLocation])
    func runner(_ runner: Runner, didUpdateLocationHeading heading: CLHeading)
    func runner(_ runner: Runner, didUpdateLocationAccuracy accuracy: Double)
}

public extension RunnerDelegate {
    func runner(_ runner: Runner, didUpdateGoalProgress progress: Progress) {}
    
    func runner(_ runner: Runner, didUpdateLocations locations: [CLLocation]) {}
    func runner(_ runner: Runner, didUpdateLocationHeading newHeading: CLHeading) {}
    func runner(_ runner: Runner, didUpdateLocationAccuracy accuracy: Double) {}
}