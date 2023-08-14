//
//  GPSTrainingType.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/12.
//

import Foundation

public enum TrainingType: Int, CaseIterable {
    
    case unknown = -1
    
    case gps_Run = 31
    case gps_Cycling = 32
    case gps_TrailRun = 33
    case gps_Onfoot = 34
    case gps_Walking = 30
    case walking = 0
    case running = 1
    case cycling = 2
    case skipping = 3
    case badminton = 4
    case basketball = 5
    case football = 6
    case climbing = 8
    case tennis = 9
    case rugby = 10
    case golf = 11
    case yoga = 12
    case fitness = 13
    case dancing = 14
    case baseball = 15
    case elliptical = 16
    case indoorCycling = 17
    case freeTraining = 18
    case rowing_machine = 19
}
