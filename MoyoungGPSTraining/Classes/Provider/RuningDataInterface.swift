//
//  RuningDataInterface.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/9.
//

import Foundation
import CoreLocation



public typealias IntHandler = ((_ value: Int) -> Void)
public typealias DoubleHandler = ((_ value: Double) -> Void)
public typealias LocationsHandler = ((_ value: [CLLocation]) -> Void)

public typealias RuningProvider = RuningDataInterface

public protocol RuningDataInterface: NSObjectProtocol {
    
    var stepsHandler: IntHandler? { get set }
    var distanceHandler: DoubleHandler? { get set }
    var calorieHandler: IntHandler? { get set }
    var speedHandler: DoubleHandler? { get set }
    var heartHandler: IntHandler? { get set }
    
    func calculateElevation() -> Double
    
    func start()
    func pause()
    func stop()
}
