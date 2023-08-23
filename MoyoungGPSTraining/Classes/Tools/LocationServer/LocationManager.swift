////
////  LocationManager.swift
////  MoyoungGPSTraining
////
////  Created by 李然 on 2023/8/23.
////
//
//import Foundation
//import CoreLocation
//
//public class LocationManager: NSObject {
//    
//    /// 水平过滤精度
//    public var horizontalAccuracy: Double = 50.0
//    
//    /// 定位点更新间隔，默认 2s
//    public var locationUpdateTimeInterval: TimeInterval = 2
//    
//    /// 坐标信任评估
//    public var coordinateTrustor: CoordinateTrustProtocol?
//    
//    /// 当前授权状态
//    public var currentAuthorizationStatus: CLAuthorizationStatus {
//        if #available(iOS 14.0, *) {
//            return locationManager.authorizationStatus
//        }
//        return CLLocationManager.authorizationStatus()
//    }
//    
//    /// 海拔卡尔曼滤波器
//    private let altitudeKalman = KalmanAltitude(qMetresPerSecond: 3)
//    
//    /// 坐标卡尔曼滤波器
//    private let coordinatesKalman = KalmanCoordinates(qMetresPerSecond: 4)
//    
//    /// CLLocationManagerDelegate代理方法
//    @objc public var locationManagerDelegate: CLLocationManagerDelegate?
//    
//    /// 是否可以定位
//    public var locationEnabled: Bool {
//        return self.currentAuthorizationStatus == .authorizedAlways || self.currentAuthorizationStatus == .authorizedWhenInUse || self.currentAuthorizationStatus == .authorizedAlways
//    }
//    
//    public static let shared = LocationManager()
//    
//    public private(set) lazy var locationManager: CLLocationManager = {
//        let manager = CLLocationManager()
//        manager.distanceFilter = kCLDistanceFilterNone
//        manager.desiredAccuracy = kCLLocationAccuracyBest
//        manager.pausesLocationUpdatesAutomatically = false
//        manager.allowsBackgroundLocationUpdates = true
//        
//        if #available(iOS 12.0, *) {
//            manager.activityType = .airborne
//        } else {
//            manager.activityType = .fitness
//        }
//        // 后台定位指示器
//        if #available(iOS 11.0, *) {
//            manager.showsBackgroundLocationIndicator = true
//        }
//        manager.delegate = self
//        return manager
//    }()
//    
//    /// 开始定位
//    public func startUpdating() {
//        guard locationEnabled else {
//            return
//        }
//        locationManager.startUpdatingLocation()
//        locationManager.startUpdatingHeading()
//    }
//    
//    /// 结束定位
//    public func stopUpdating() {
//        guard locationEnabled else {
//            return
//        }
//        locationManager.stopUpdatingLocation()
//        locationManager.stopUpdatingHeading()
//    }
//    
//    /// 暂停定位
//    public func pauseUpdating() {
//        self.stopUpdating()
//        self.altitudeKalman.reset()
//        self.coordinatesKalman.reset()
//    }
//}
//
//extension LocationManager: CLLocationManagerDelegate {
//    
//    /// 权限变化
//    /// - Parameter manager: self
//    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        if #available(iOS 14.0, *) {
//            locationManagerDelegate?.locationManagerDidChangeAuthorization?(manager)
//            
//            let note = Notification(name: .locationDidChangeAuthorizationStatus, object: self, userInfo: ["status": CLLocationManager.authorizationStatus()])
//            NotificationCenter.default.post(note)
//        } else {
//            // Fallback on earlier versions
//        }
//    }
//    
//    /// 当前 大头钉 更新
//    /// - Parameters:
//    ///   - manager: self
//    ///   - newHeading: 大头钉
//    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        locationManagerDelegate?.locationManager?(manager, didUpdateHeading: newHeading)
//        
//        if newHeading.headingAccuracy < 0 {
//            return
//        } else {
//            let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
//            let rotation = heading / 180.0 * CGFloat.pi
//            
//            let note = Notification(name: .locationDidUpdateHeadingAngle, object: self, userInfo: ["headingAngle": rotation])
//            NotificationCenter.default.post(note)
//        }
//    }
//    
//    /// 出错
//    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        locationManagerDelegate?.locationManager?(manager, didFailWithError: error)
//        
//        let note = Notification(name: .locationDidFailWithError, object: self, userInfo: ["error": error])
//        NotificationCenter.default.post(note)
//    }
//    
//    /// 权限变化
//    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        locationManagerDelegate?.locationManager?(manager, didChangeAuthorization: status)
//        
//        let note = Notification(name: .locationDidChangeAuthorizationStatus, object: self, userInfo: ["status": status])
//        NotificationCenter.default.post(note)
//    }
//    
//    /// 获取坐标
//    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        locationManagerDelegate?.locationManager?(manager, didUpdateLocations: locations)
//        
//        let note = Notification(name: .locationDidUpdateLocations, object: self, userInfo: ["locations": locations])
//        NotificationCenter.default.post(note)
//        
//        for location in locations {
//            guard location.horizontalAccuracy <= self.horizontalAccuracy,
//                  abs(location.timestamp.timeIntervalSinceNow) < self.locationUpdateTimeInterval else {
//                continue
//            }
//            
//            location.countryCodeUserWGS { [weak self] isWGS in
//                
//                guard let `self` = self else { return }
//                
//                var GCJLocations = self.filterLocation(location)
//                
//                /// 卡尔曼滤波
//                if let location = self.kalmanLocation(GCJLocations) {
//                    GCJLocations = location
//                }
//                
//                var coordinate = location.coordinate
//                if isWGS {
//                    coordinate = coordinate.transformFormWGSToGCJ()
//                }
//                
//                GCJLocations = CLLocation(coordinate: coordinate, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: location.timestamp)
//                
//                
//            }
//        
//            
////            self.locationSignalRange = GPSTrainingLocationSignalRange.range(with: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy)
//        }
//    }
//    
//    private func filterLocation(_ location: CLLocation) -> CLLocation {
//        guard let coordinateTrustor = self.coordinateTrustor,
//              let fudgeLocation = coordinateTrustor.fudgedLocation(location)
//        else {
//            return location
//        }
//        
//        return fudgeLocation
//    }
//    
//    private func kalmanLocation(_ location: CLLocation) -> CLLocation? {
//        self.altitudeKalman.add(location: location)
//        self.coordinatesKalman.add(location: location)
//        
//        guard let kalCoord = coordinatesKalman.coordinate,
//              let rawLoc = coordinatesKalman.unfilteredLocation
//        else {
//            return nil
//        }
//
//        if let kalAlt = altitudeKalman.altitude, let rawAltLoc = altitudeKalman.unfilteredLocation {
//            return CLLocation(coordinate: kalCoord, altitude: kalAlt, horizontalAccuracy: rawLoc.horizontalAccuracy,
//                              verticalAccuracy: rawAltLoc.verticalAccuracy, course: rawLoc.course, speed: rawLoc.speed,
//                              timestamp: self.coordinatesKalman.date)
//
//        } else {
//            return CLLocation(coordinate: kalCoord, altitude: 0, horizontalAccuracy: rawLoc.horizontalAccuracy,
//                              verticalAccuracy: -1, course: rawLoc.course, speed: rawLoc.speed,
//                              timestamp: self.coordinatesKalman.date)
//        }
//    }
//
//}
