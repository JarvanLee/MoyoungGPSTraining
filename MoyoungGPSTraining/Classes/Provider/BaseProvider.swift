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
public typealias TrainingLineHandler = (_ value: GPSTrainingLine) -> Void

open class BaseProvider: NSObject {
    
    // 步数回调
    public var stepsHandler: IntHandler?
    // 卡路里回调
    public var calorieHandler: IntHandler?
    // 心率回调
    public var heartHandler: IntHandler?
    
    //MARK: - GPS相关
    // 定位权限回调
    public var authorizationStatusHandler: LocationsAuthStatusHandler?
    // 定位失败回调
    public var locationFailHandler: ((_ error: Error) -> Void)?
    // 定位点
    public var locationsHander: LocationsHandler?
    // 定位头角度
    public var headingAngleHandler: DoubleHandler?
    // 信号强度
    public var locationSingleHandler: LocationSingleHandler?
    // 爬升高度数组
    public var altitudeListHandler: DoubleListHandler?
    // 距离（可能是GPS，可能是手机计步器）
    public var distanceHandler: DoubleHandler?
    // 瞬时速度（可能是GPS，可能是手机计步器）
    public var speedHandler: DoubleHandler?
    // 锻炼段
    public var trainingLineHandler: TrainingLineHandler?
    
    /// 是否需要GPS定位
    public var isGPSRequird: Bool {
        return self.locationManager != nil
    }
    
    public private(set) var locationManager: GPSTrainingLocationManager?
    public private(set) var locations: [CLLocation] = []
    public private(set) var trainingLines: [GPSTrainingLine] = []
    private var currentLine: GPSTrainingLine?
    
    var gpsDistance: Double {
        return trainingLines.reduce(0, { $0 + $1.locations.distance })
    }
    var gpsCurrentSpeed: Double {
        return locations.last?.speed ?? 0.0
    }
    
    public init(locationManager: GPSTrainingLocationManager? = nil) {
        self.locationManager = locationManager
        super.init()
    }
    
    /// 手动设置心率
    open func setHeartRate(_ heart: Int) {}
    
    /// 手动设置步数
    open func setSteps(_ steps: Int) {}
    
    /// 手动设置卡路里
    open func setCalorie(_ calorie: Int) {}
    
    open func start() {
        if self.isGPSRequird {
            self.locationManager?.locationsUpdateHandler = { [weak self] location in
                guard let `self` = self else { return }
                self.locations.append(location)
                self.currentLine?.add(location: location)
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
            self.locationManager?.startUpdating()
            
            if self.currentLine == nil {
                self.currentLine = GPSTrainingLine()
            }
        }
    }
    
    open func pause() {
        if self.isGPSRequird {
            self.locationManager?.pauseUpdating()
            if let line = self.currentLine {
                self.trainingLines.append(line)
                self.currentLine = nil
            }
        }
    }
    
    open func stop() {
        if self.isGPSRequird {
            self.locationManager?.stopUpdating()
            self.locationManager = nil
            self.locations = []
            self.trainingLines = []
            self.currentLine = nil
        }
    }
    
    open func calculateElevation() -> Double? {
        guard isGPSRequird else {
            return nil
        }
        var elevation: Double = 0
        
        guard locations.count >= 2 else {
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
            if let line = self.currentLine {
                self.trainingLineHandler?(line)
            }
        }
    }
}
