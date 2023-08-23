//
//  Notifications.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/23.
//

import Foundation

extension Notification.Name {
    public static let locationDidChangeAuthorizationStatus = Notification.Name("Moyoung.Location.DidChangeAuthorizationStatus")
    public static let locationDidUpdateLocations = Notification.Name("Moyoung.Location.DidUpdateLocations")
    public static let locationDidUpdateHeadingAngle = Notification.Name("Moyoung.Location.DidUpdateHeadingAngle")
    public static let locationDidFailWithError = Notification.Name("Moyoung.Location.DidFailWithError")
    public static let locationDidUptateSignalAccuracy = Notification.Name("Moyoung.Location.DidUptateSignalAccuracy")
}
