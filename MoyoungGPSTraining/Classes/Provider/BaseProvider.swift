//
//  BaseProvider.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/18.
//

import Foundation
import CoreLocation
import TQLocationConverter

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
    
    // MARK: - GPS相关
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
    // 爬升高度
    public var altitudeHandler: ((_ total: Double, _ detail: [Double]) -> Void)?
    // 距离（可能是GPS，可能是手机计步器）
    public var distanceHandler: DoubleHandler?
    // 瞬时速度（可能是GPS，可能是手机计步器）
    public var speedHandler: DoubleHandler?
    // 锻炼段
    public var trainingLineHandler: TrainingLineHandler?
    
    public let isLocationRequird: Bool
    public private(set) var locations: [CLLocation] = []
    public private(set) var trainingLines: [GPSTrainingLine] = []
    
    var gpsDistance: Double {
        return trainingLines.reduce(0, { $0 + $1.locations.distance })
    }
    var gpsCurrentSpeed: Double {
        return locations.last?.speed ?? 0.0
    }
    
    public init(isLocationRequird: Bool = false) {
        self.isLocationRequird = isLocationRequird
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 手动设置心率
    open func setHeartRate(_ heart: Int) {}
    
    /// 手动设置步数
    open func setSteps(_ steps: Int) {}
    
    /// 手动设置卡路里
    open func setCalorie(_ calorie: Int) {}
    
    open func start() {
        if self.isLocationRequird {
            let loco = LocationManager.shared
            loco.startUpdating()
            
            when(loco, does: .locationDidUpdateLocation) { [weak self] _ in
                guard let `self` = self else { return }
                if let location = loco.locomotionSample().location {
                    
                    CLGeocoder().reverseGeocodeLocation(location) { (placemarks: [CLPlacemark]?, error: Error?) in
                        
                        var isChina = false
                        
                        if let placemark = placemarks?.first {
                            let countryCode = placemark.isoCountryCode
                            isChina = countryCode == "CN" || countryCode == "HK" || countryCode == "MO"
                        } else {
                            isChina = !TQLocationConverter.isLocationOut(ofChina: location.coordinate)
                        }
                        if isChina {
                            let coordinate = TQLocationConverter.transformFromWGS(toGCJ: location.coordinate)
                            let newLocation = CLLocation(coordinate: coordinate,
                                                         altitude: location.altitude,
                                                         horizontalAccuracy: location.horizontalAccuracy,
                                                         verticalAccuracy: location.verticalAccuracy,
                                                         course: location.course,
                                                         speed: location.speed,
                                                         timestamp: location.timestamp)
                            self.addNewLocation(newLocation)
                        } else {
                            self.addNewLocation(location)
                        }
                    }
                }
            }
            when(loco, does: .locationDidUpdateHeadingAngle) { [weak self] note in
                guard let `self` = self else { return }
                if let angle = note.userInfo?["headingAngle"] as? CGFloat {
                    self.headingAngleHandler?(angle)
                }
            }
            when(loco, does: .locationDidUptateSignalAccuracy) { [weak self] note in
                guard let `self` = self else { return }
                if let signal = note.userInfo?["signal"] as? GPSTrainingLocationSignalRange {
                    self.locationSingleHandler?(signal)
                }
            }
            when(loco, does: .locationDidChangeAuthorizationStatus) { [weak self] note in
                guard let `self` = self else { return }
                if let status = note.userInfo?["status"] as? CLAuthorizationStatus {
                    self.authorizationStatusHandler?(status)
                }
            }
            when(loco, does: .locationDidFailWithError) { [weak self] note in
                guard let `self` = self else { return }
                if let error = note.userInfo?["error"] as? Error {
                    self.locationFailHandler?(error)
                }
            }
            
            self.trainingLines.append(GPSTrainingLine())
        }
    }
    
    open func pause() {
        if self.isLocationRequird {
            LocationManager.shared.pauseUpdating()
        }
    }
    
    open func stop() {
        if self.isLocationRequird {
            LocationManager.shared.stopUpdating()
        }
    }
    
    open func calculateElevation() -> Double? {
        guard isLocationRequird else {
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
        if isLocationRequird {
            self.distanceHandler?(self.gpsDistance)
            self.speedHandler?(self.gpsCurrentSpeed)
            self.locationsHander?(self.locations)
            self.altitudeHandler?(self.calculateElevation() ?? 0.0, self.locations.map { $0.altitude })
            if let line = self.trainingLines.last {
                self.trainingLineHandler?(line)
            }
        }
    }
    
    private func addNewLocation(_ location: CLLocation) {
        self.locations.append(location)
        self.trainingLines.last?.add(location: location)
        self.syncGPSData()
    }
}
