//
//  BaseProvider.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/18.
//

import Foundation
import CoreLocation

public typealias IntHandler = (_ value: Int) -> Void
public typealias DoubleHandler = (_ value: Double) -> Void
public typealias DoubleListHandler = (_ value: [Double]) -> Void
public typealias LocationsHandler = (_ value: [CLLocation]) -> Void
public typealias LocationsAuthStatusHandler = (_ value: CLAuthorizationStatus) -> Void
public typealias LocationSingleHandler = (_ value: GPSTrainingLocationSignalRange) -> Void

open class BaseProvider: NSObject {
    
    // 步数回调
    var stepsHandler: IntHandler?
    // 卡路里回调
    var calorieHandler: IntHandler?
    // 心率回调
    var heartHandler: IntHandler?
    
    //MARK: - GPS相关
    // 定位权限回调
    var authorizationStatusHandler: LocationsAuthStatusHandler?
    // 定位失败回调
    var locationFailHandler: ((_ error: Error) -> Void)?
    // 定位点
    var locationsHander: LocationsHandler?
    // 定位头角度
    var headingAngleHandler: DoubleHandler?
    // 信号强度
    var locationSingleHandler: LocationSingleHandler?
    // 爬升高度数组
    var altitudeListHandler: DoubleListHandler?
    // 距离（可能是GPS，可能是手机计步器）
    var distanceHandler: DoubleHandler?
    // 瞬时速度（可能是GPS，可能是手机计步器）
    var speedHandler: DoubleHandler?
    
    /// 锻炼类型
    let traningType: TrainingType
    /// 是否需要GPS定位
    var isGPSRequird: Bool {
        return self.traningType != .indoorRunning && self.traningType != .indoorWalking
    }
    
    var locationManager: GPSTrainingLocationManager?
    var locations: [CLLocation] = []
    var gpsDistance: Double {
        var distance: CLLocationDistance = 0
        if locations.count > 1 {
            var currentLocation: CLLocation? = nil
            for location in locations {
                if currentLocation != nil {
                    distance += location.distance(from: currentLocation!)
                }
                currentLocation = location
            }
        }
        return distance
    }
    var gpsCurrentSpeed: Double {
        return locations.last?.speed ?? 0.0
    }
    
    public init(traningType: TrainingType) {
        self.traningType = traningType
        super.init()
    }
    
    /// 手动设置心率
    public func setHeartRate(_ heart: Int) {}
    
    /// 手动设置步数
    public func setSteps(_ steps: Int) {}
    
    /// 手动设置卡路里
    public func setCalorie(_ calorie: Int) {}
    
    open func start() {
        if self.isGPSRequird {
            if self.locationManager == nil {
                self.locationManager = GPSTrainingLocationManager()
                self.locationManager?.trainingType = traningType
                self.locationManager?.locationsUpdateHandler = { [weak self] location in
                    guard let `self` = self else { return }
                    self.locations.append(location)
                    self.syncGPSData()
                }
                self.locationManager?.headingAngleUpdateHandler = { [weak self] angle in
                    guard let `self` = self else { return }
                    self.headingAngleHandler?(angle)
                }
                self.locationManager?.signalAccuracyUpdateHandler = { [weak self] signal in
                    guard let `self` = self else { return }
                    self.locationSingleHandler?(signal)
                }
                self.locationManager?.authorizationStatusHandler = { [weak self] state in
                    guard let `self` = self else { return }
                    self.authorizationStatusHandler?(state)
                }
                self.locationManager?.locationFailHandler = { [weak self] error in
                    guard let `self` = self else { return }
                    self.locationFailHandler?(error)
                }
            }
            self.locationManager?.startUpdating()
        }
    }
    
    open func pause() {
        if self.isGPSRequird {
            self.locationManager?.pauseUpdating()
        }
    }
    
    open func stop() {
        if self.isGPSRequird {
            self.locationManager?.stopUpdating()
            self.locationManager = nil
            self.locations = []
        }
    }
    
    func calculateElevation() -> Double? {
        guard isGPSRequird else {
            return nil
        }
        var elevation: Double = 0

        if locations.count < 2 {
            return elevation
        }

        var minLocation: CLLocation?
        var maxLocation: CLLocation?

        for i in 1 ..< (locations.count - 1) {
            let last = locations[i - 1]
            let current = locations[i]
            let next = locations[i + 1]

            if current.altitude >= last.altitude && current.altitude > next.altitude {
                maxLocation = current
            }
            // 最后一个还是上坡
            if i == locations.count - 2 && current.altitude < next.altitude {
                maxLocation = next
            }

            if current.altitude <= last.altitude && current.altitude < next.altitude {
                minLocation = current
            }

            // 第一段是下坡
            if i == 1 && current.altitude > last.altitude {
                minLocation = last
            }

            if let max = maxLocation, let min = minLocation {
                let d = max.altitude - min.altitude
                if min.altitude < max.altitude && d < 2.0 {
                    elevation += d
                }
                maxLocation = nil
                minLocation = nil
            }
        }
        return elevation
    }
    
    func syncGPSData() {
        if isGPSRequird {
            self.distanceHandler?(self.gpsDistance)
            self.speedHandler?(self.gpsCurrentSpeed)
            self.locationsHander?(self.locations)
            self.altitudeListHandler?(self.locations.map { $0.altitude })
        }
    }
}
