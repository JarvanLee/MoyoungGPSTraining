//
//  NotificationNames.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/10.
//

import Foundation

extension Notification.Name {
    static let locationsUpdate = Notification.Name("MoyoungGPSTraining.Locations.Update")
    static let locationHeadUpdate = Notification.Name("MoyoungGPSTraining.Location.Head.Update")
    static let gpsAccuracyUpdate = Notification.Name("MoyoungGPSTraining.GPS.Accuracy.Update")
}
