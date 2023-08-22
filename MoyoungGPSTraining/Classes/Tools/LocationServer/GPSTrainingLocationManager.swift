//
//  GPSTrainingLocationManager.swift
//  DaRings
//
//  Created by 尹琼 on 2023/7/29.
//

import UIKit
import CoreLocation

open class GPSTrainingLocationManager: CLLocationManager {
    
    // 水平过滤精度
    public var horizontalAccuracy: Double = 20.0
    
    // 是否开启过滤,默认开启
    public var filterable: Bool = true
    
    // 定位点更新间隔，默认 2s
    public var locationUpdateTimeInterval: TimeInterval = 2.0
    
    /// 坐标信任评估
    public var coordinateTrustor: CoordinateTrustProtocol?
    
    /// 海拔卡尔曼滤波器
    private let altitudeKalman = KalmanAltitude(qMetresPerSecond: 3)
    
    /// 坐标卡尔曼滤波器
    private let coordinatesKalman = KalmanCoordinates(qMetresPerSecond: 4)
    
    // -1 代表无效
    public var headingAngle: CGFloat = -1.0 {
        
        didSet {
            
            if headingAngle > -1.0 {
                
                self.headingAngleUpdateHandler?(headingAngle)
                
            }
        }
        
    }
    
    
    /// 当前信号区间
    public var locationSignalRange: GPSTrainingLocationSignalRange = .none {
        
        didSet {
            if locationSignalRange != oldValue {
                signalAccuracyUpdateHandler?(locationSignalRange)
            }
        }
    }
    
    /// 当前授权状态
    public var currentAuthorizationStatus: CLAuthorizationStatus {
        
        if #available(iOS 14.0, *) {
            return self.authorizationStatus
        }
        return CLLocationManager.authorizationStatus()
    }
    
    /// 角度更新回调
    public var headingAngleUpdateHandler: ((_ angle: Double) ->Void)?
    
    /// 权限变化回调
    public var authorizationStatusHandler: ((_ authorizationStatus: CLAuthorizationStatus) ->Void)?
    
    /// 信号区间更新回调
    public var signalAccuracyUpdateHandler: ((_ signalAccuracy: GPSTrainingLocationSignalRange) ->Void)?
    
    
    /// 定位点更新回调
    /// location：永远返回使用的点，如果使用了过滤算法，将返回过滤后的坐标
    /// 注意：是地球坐标系
    public var locationsUpdateHandler: ((_ location: CLLocation) ->Void)?
    
    /// 定位点更新回调
    /// rawLocation: 永远返回传感器原生坐标,
    /// 注意：是地球坐标系
    public var rawLocationsUpdateHandler: ((_ location: CLLocation) ->Void)?

    
    /// 定位失败回调
    public var locationFailHandler: ((_ error: Error) ->Void)?
    
    
    /// 是否可以定位
    public var locationEnabled: Bool {
        
        if !CLLocationManager.locationServicesEnabled() {
            return false
        }
        return self.currentAuthorizationStatus == .authorizedAlways || self.currentAuthorizationStatus == .authorizedWhenInUse || self.currentAuthorizationStatus == .authorizedAlways
    }

   
    internal var lastLocation: CLLocation?
    
    public override init() {
        super.init()
        
        config()
    }
    
    
    
    
    open func config() {
        
        self.delegate = self
        
        // 设置定位进度
        self.desiredAccuracy = kCLLocationAccuracyBest
        
        // 更新距离
        self.distanceFilter = 5
        
        if #available(iOS 12.0, *) {
            self.activityType = .airborne
        } else {
            self.activityType = .fitness
        }
        
        self.pausesLocationUpdatesAutomatically = false
        
        self.allowsBackgroundLocationUpdates = true
        
        
        // 后台定位指示器
        if #available(iOS 11.0, *) {
            self.showsBackgroundLocationIndicator = true
        }
        
    }
    
    /// 优先级授权请求
    /// 先按照 status 要求，请求权限
    /// 如果 已经是 authorizedWhenInUse 权限，将请求 authorizedAlways 权限
    open func requestAuthorization(_ status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            
            if self.currentAuthorizationStatus == .authorizedWhenInUse {
                
                self.requestAlwaysAuthorization()
                
            } else {
                
                self.requestWhenInUseAuthorization()
            }
            
            
        } else {
            
            self.requestAlwaysAuthorization()
            
        }
        
    }
    
    /// 开始定位
    open func startUpdating() {
        
        if !self.locationEnabled {
            return
        }
        
        self.startUpdatingLocation()
        self.startUpdatingHeading()
    }
    
    /// 结束定位
    open func stopUpdating() {
        
        if !self.locationEnabled {
            return
        }
        
        self.stopUpdatingLocation()
        self.stopUpdatingHeading()
        
    }
    
    
    /// 暂停定位
    open func pauseUpdating() {
        
        self.stopUpdating()
        self.altitudeKalman.reset()
        self.coordinatesKalman.reset()
        
    }
    
    
}

extension GPSTrainingLocationManager: CLLocationManagerDelegate {
    
    /// 权限变化
    /// - Parameter manager: self
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        authorizationStatusHandler?(CLLocationManager.authorizationStatus())
        
    }
    
    /// 当前 大头钉 更新
    /// - Parameters:
    ///   - manager: self
    ///   - newHeading: 大头钉
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 {
            return
        }else {
            let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
            let rotation = heading / 180.0 *  CGFloat.pi
            
            self.headingAngle = rotation
            
            
        }
    }
    
    /// 获取的火星坐标系
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        for location in locations {
            
            guard location.horizontalAccuracy < self.horizontalAccuracy,
                  abs(location.timestamp.timeIntervalSinceNow) < self.locationUpdateTimeInterval else {
                continue
            }
            
            location.countryCodeUserWGS(handler: {[weak self] isWGS in
                
                
                guard let self = self else { return }
                
                if let rawLocationsUpdateHandler = self.rawLocationsUpdateHandler  {
                    
                    let GCJLocations = CLLocation(coordinate: location.coordinate, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: location.timestamp)
                    
                    rawLocationsUpdateHandler(GCJLocations)
                }
                
                
                /// 未开启过滤
                if !self.filterable, self.locationsUpdateHandler == nil {
                    return
                }
                
                /// 速度均值过滤
                var GCJLocations = self.filterLocation(location)
                
                /// 卡尔曼滤波
                if let location = self.kalmanLocation(GCJLocations) {
                    GCJLocations = location
                }
                
                var coordinate = location.coordinate
                if isWGS {
                    coordinate = coordinate.transformFormWGSToGCJ()
                }
                
                GCJLocations = CLLocation(coordinate: coordinate, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: location.timestamp)
                
            
                self.locationsUpdateHandler?(GCJLocations)

                
            })
            
            locationSignalRange = GPSTrainingLocationSignalRange.range(with: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy)
            
        }
        
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        self.locationFailHandler?(error)
    }
    
    
    fileprivate func filterLocation(_ location: CLLocation) ->CLLocation {
        
        guard let coordinateTrustor = self.coordinateTrustor,
              let fudgeLocation = coordinateTrustor.fudgedLocation(location) else
        {
            return location
            
        }
        
        return fudgeLocation
        
        
    }
    
    
    func kalmanLocation(_ location: CLLocation) -> CLLocation? {
        
        altitudeKalman.add(location: location)
        coordinatesKalman.add(location: location)
        
        
        guard let kalCoord = coordinatesKalman.coordinate,
              let rawLoc = coordinatesKalman.unfilteredLocation
        else {
            return nil
        }

        if let kalAlt = altitudeKalman.altitude, let rawAltLoc = altitudeKalman.unfilteredLocation {
            return CLLocation(coordinate: kalCoord, altitude: kalAlt, horizontalAccuracy: rawLoc.horizontalAccuracy,
                              verticalAccuracy: rawAltLoc.verticalAccuracy, course: rawLoc.course, speed: rawLoc.speed,
                              timestamp: coordinatesKalman.date)

        } else {
            return CLLocation(coordinate: kalCoord, altitude: 0, horizontalAccuracy: rawLoc.horizontalAccuracy,
                              verticalAccuracy: -1, course: rawLoc.course, speed: rawLoc.speed,
                              timestamp: coordinatesKalman.date)
        }
    }

}




public enum GPSTrainingLocationStatus {
    
    case sucess
    case fail
    
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
        
        guard let range = Self.allCases.filter({ $0.range.contains(horizontalAccuracyInt) }).first else {
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


extension CLLocation {
    
    public func countryCodeUserWGS(handler: ((_ isWGS: Bool) ->Void)?) {
        
        
        countryCode { countryCode in
            
            let isWGS = countryCode == "CN" || countryCode == "HK" || countryCode == "MO"
            
            handler?(isWGS)
        }
        
    }
    
    public func countryCode(handler: ((_ countryCode: String?) ->Void)?) {
        
        
        CLGeocoder().reverseGeocodeLocation(self) { (placemarks: [CLPlacemark]?, error: Error?) in
            
            var countryCode: String?
            guard let placemark = placemarks?.first else {
                handler?(countryCode)
                return
            }
            
            countryCode = placemark.isoCountryCode
            handler?(countryCode)
            
        }
    }
    
    
}

extension CLLocationCoordinate2D {
    
    
    public func transformFormWGSToGCJ() -> CLLocationCoordinate2D {
        
        var gcjLoc: CLLocationCoordinate2D = CLLocationCoordinate2D()
        var adjustLat: Double = self.transformLat(x: self.longitude - 105.0, y: self.latitude - 35.0)
        var adjustLon: Double = self.transformLon(x: self.longitude - 105.0, y: self.latitude - 35.0)
        let radLat = self.latitude / 180.0 * self.π
        var magic = sin(radLat)
        magic = 1 - self.ee * magic * magic
        let sqrtMagic: Double = sqrt(magic)
        adjustLat = (adjustLat * 180.0) / ((self.a * (1 - self.ee)) / (magic * sqrtMagic) * self.π)
        adjustLon = (adjustLon * 180.0) / (self.a / sqrtMagic * cos(radLat) * self.π)
        gcjLoc.longitude = self.longitude + adjustLon
        gcjLoc.latitude = self.latitude + adjustLat
        
        return gcjLoc
        
    }
    
    public func transformLat(x: Double ,y: Double) -> Double{
        let tempSqrtLat = 0.2 * sqrt(abs(x))
        var lat: Double = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + tempSqrtLat
        lat += (20.0 * sin(6.0 * x * π) + 20.0 * sin(2.0 * x * π)) * 2.0 / 3.0
        lat += (20.0 * sin(y * π) + 40.0 * sin(y / 3.0 * π)) * 2.0 / 3.0;
        lat += (160.0 * sin(y / 12.0 * π) + 320 * sin(y * π / 30.0)) * 2.0 / 3.0;
        return lat
    }
    
    public func transformLon(x: Double, y: Double) -> Double {
        let tempSqrtLon = 0.1 * sqrt(abs(x))
        var lon: Double = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + tempSqrtLon
        lon += (20.0 * sin(6.0 * x * π) + 20.0 * sin(2.0 * x * π)) * 2.0 / 3.0
        lon += (20.0 * sin(x * π) + 40.0 * sin(x / 3.0 * π)) * 2.0 / 3.0
        lon += (150.0 * sin(x / 12.0 * π) + 300.0 * sin(x / 30.0 * π)) * 2.0 / 3.0
        return lon
    }
    
    
    fileprivate var π: Double {
        return Double.pi
        
    }
    
    fileprivate var ee: Double {
        return 0.00669342162296594323
        
    }
    fileprivate  var a: Double {
        return 6378245.0
    }
    
}
