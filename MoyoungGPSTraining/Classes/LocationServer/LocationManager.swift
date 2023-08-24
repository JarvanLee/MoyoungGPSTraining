//
//  LocationManager.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/23.
//

import Foundation
import CoreLocation

public class LocationManager: NSObject {

    /// 坐标信任评估
    public var coordinateAssessor: TrustAssessor?

    /// 最大水平精度
    public var maximumHorizontalAccuracy = 40.0

    /// 当前授权状态
    public var currentAuthorizationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        }
        return CLLocationManager.authorizationStatus()
    }

    /// CLLocationManagerDelegate代理方法
    @objc public var locationManagerDelegate: CLLocationManagerDelegate?

    /// 是否可以定位
    public var locationEnabled: Bool {
        return self.currentAuthorizationStatus == .authorizedAlways || self.currentAuthorizationStatus == .authorizedWhenInUse || self.currentAuthorizationStatus == .authorizedAlways
    }
    
    public func locomotionSample() -> LocomotionSample {
        return LocomotionSample(from: ActivityBrain.highlander.presentSample)
    }

    public static let shared = LocationManager()

    public private(set) lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.distanceFilter = kCLDistanceFilterNone
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true

        if #available(iOS 12.0, *) {
            manager.activityType = .airborne
        } else {
            manager.activityType = .fitness
        }
        // 后台定位指示器
        if #available(iOS 11.0, *) {
            manager.showsBackgroundLocationIndicator = true
        }
        manager.delegate = self
        return manager
    }()

    /// 开始定位
    public func startUpdating() {
        guard locationEnabled else {
            return
        }
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    /// 结束定位
    public func stopUpdating() {
        guard locationEnabled else {
            return
        }
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    /// 暂停定位
    public func pauseUpdating() {
        self.stopUpdating()
    }

    internal var lastLocation: CLLocation?
}

extension LocationManager: CLLocationManagerDelegate {

    /// 权限变化
    /// - Parameter manager: self
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            locationManagerDelegate?.locationManagerDidChangeAuthorization?(manager)

            let note = Notification(name: .locationDidChangeAuthorizationStatus, object: self, userInfo: ["status": CLLocationManager.authorizationStatus()])
            NotificationCenter.default.post(note)
        } else {
            // Fallback on earlier versions
        }
    }

    /// 当前 大头钉 更新
    /// - Parameters:
    ///   - manager: self
    ///   - newHeading: 大头钉
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        locationManagerDelegate?.locationManager?(manager, didUpdateHeading: newHeading)

        if newHeading.headingAccuracy < 0 {
            return
        } else {
            let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
            let rotation = heading / 180.0 * CGFloat.pi

            let note = Notification(name: .locationDidUpdateHeadingAngle, object: self, userInfo: ["headingAngle": rotation])
            NotificationCenter.default.post(note)
        }
    }

    /// 出错
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManagerDelegate?.locationManager?(manager, didFailWithError: error)

        let note = Notification(name: .locationDidFailWithError, object: self, userInfo: ["error": error])
        NotificationCenter.default.post(note)
    }

    /// 权限变化
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManagerDelegate?.locationManager?(manager, didChangeAuthorization: status)

        let note = Notification(name: .locationDidChangeAuthorizationStatus, object: self, userInfo: ["status": status])
        NotificationCenter.default.post(note)
    }

    /// 获取坐标
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManagerDelegate?.locationManager?(manager, didUpdateLocations: locations)

        let note = Notification(name: .locationDidUpdateRawLocations, object: self, userInfo: ["locations": locations])
        NotificationCenter.default.post(note)

        // feed the brain
        var addedLocations = false
        for location in locations {
        
            guard location.horizontalAccuracy < maximumHorizontalAccuracy else {
                continue
            }
            
            // new location is too soon, and not better than previous? skip it
            if let last = lastLocation,
               last.horizontalAccuracy <= location.horizontalAccuracy,
                last.timestamp.age < 1.1 {
                continue
            }
            
            if let trustFactor = self.coordinateAssessor?.trustFactorFor(location.coordinate) {
                ActivityBrain.highlander.add(rawLocation: location, trustFactor: trustFactor)
            } else {
                ActivityBrain.highlander.add(rawLocation: location)
            }

            addedLocations = true
        }
        
        if addedLocations {
            self.updateAndNotify()
        }
    }
    
    private func updateAndNotify() {
        ActivityBrain.highlander.update()
        notify()
    }
    
    private func notify() {
        if let last = self.lastLocation {
            let signal = GPSTrainingLocationSignalRange.range(with: last.horizontalAccuracy, verticalAccuracy: last.verticalAccuracy)
            let note = Notification(name: .locationDidUptateSignalAccuracy, object: self, userInfo: ["signal": signal])
            NotificationCenter.default.post(note)
        }
        NotificationCenter.default.post(Notification(name: .locationDidUpdateLocation, object: self, userInfo: nil))
    }
}

public enum GPSTrainingLocationSignalRange: Int, CaseIterable {
    case none = 0
    case weak = 1
    case moderate = 2
    case normal = 3
    case best = 4

    public var range: Range<Int> {
        switch self {
        case .best:
            return 0 ..< 5
        case .normal:
            return 5 ..< 10
        case .moderate:
            return 10 ..< 20
        case .weak:
            return 20 ..< 100
        case .none:
            return 100 ..< Int.max
        }
    }

    /// 信号区间
    public static func range(with horizontalAccuracy: CLLocationAccuracy, verticalAccuracy: CLLocationAccuracy) -> GPSTrainingLocationSignalRange {
        let accrracy = horizontalAccuracy > verticalAccuracy ? horizontalAccuracy : verticalAccuracy
        let horizontalAccuracyInt = Int(accrracy)

        guard let range = allCases.filter({ $0.range.contains(horizontalAccuracyInt) }).first else {
            return .none
        }

        return range
    }

    /// 信号可能在弱区间
    public var inWeekable: Bool {
        return self < .normal
    }
}

extension GPSTrainingLocationSignalRange: Comparable {
    public static func < (lhs: GPSTrainingLocationSignalRange, rhs: GPSTrainingLocationSignalRange) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public static func <= (lhs: GPSTrainingLocationSignalRange, rhs: GPSTrainingLocationSignalRange) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }

    public static func >= (lhs: GPSTrainingLocationSignalRange, rhs: GPSTrainingLocationSignalRange) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }

    public static func > (lhs: GPSTrainingLocationSignalRange, rhs: GPSTrainingLocationSignalRange) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }
}


