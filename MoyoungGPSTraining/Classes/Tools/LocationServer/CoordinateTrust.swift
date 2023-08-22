//
//  CoordinateTrust.swift
//  DaRings
//
//  Created by 尹琼 on 2023/8/11.
//

import UIKit
import MapKit

public protocol CoordinateTrustProtocol {
    
    func fudgedLocation(_ location: CLLocation) ->CLLocation?
    
}

/// 用于评估当前坐标是否值得信任， < 1 时，将变更坐标点燥值
open class CoordinateTrust: NSObject, CoordinateTrustProtocol {
   
    
    /// 被评估的坐标
    public var coordinate: CLLocationCoordinate2D
    
    /// 这一段被评估的坐标点
    public var locations: [CLLocation] = []
    
    /// 信任值
    public var trustFactor: Double = 1
    
    /// 最大速度限定值 -1 为无效值
    public var maximumSpeed: CLLocationSpeed = -1
    
    /// 评估个数
    public var trastLcationsCount: Int = 0
    
    public init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
    
    
    /// 更新信任值
    /// - Parameter maximumSpeed: 最大速度约束
    public func updateTrustFactor(with maximumSpeed: CLLocationSpeed) {
        
      
       if maximumSpeed <= 0.0 {
            return
        }
        
        let speeds = locations.compactMap { $0.speed }.filter { $0 >= 0 }
        let meanSpeed = speeds.mean

        trustFactor = 1.0 - (meanSpeed / maximumSpeed).clamped(min: 0, max: 1)
    }
    
    
    /// 获取不信任坐标点
    /// - Parameter location: 测量坐标点
    /// - Returns: 为 nil 表示 测量坐标点值得信任
    public func fudgedLocation(_ location: CLLocation) ->CLLocation? {
        
        if self.maximumSpeed < 0 {
            return nil
        }
        
        self.locations.append(location)
        self.trastLcationsCount += 1
        
        /// 每1000m 评估一次,  < 1000 个点，每次都评估
        if self.trastLcationsCount < 1000 {
            self.updateTrustFactor(with: self.maximumSpeed)
        } else {
            
            if self.trastLcationsCount % 1000 == 0 {
                self.updateTrustFactor(with: self.maximumSpeed)
                self.locations.removeAll()
            }
        }
        
        
        if self.trustFactor >= 1 {
            
            return nil
        }
  
        let accuracyFudge = kCLLocationAccuracyHundredMeters * (1.0 - self.trustFactor)
        let fudgedLocation = CLLocation(
            coordinate: location.coordinate, altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy + accuracyFudge,
            verticalAccuracy: location.verticalAccuracy + accuracyFudge,
            course: location.course, speed: location.speed,
            timestamp: location.timestamp)
        
        return fudgedLocation
        
    }

}

public extension Array where Element: FloatingPoint {

    var sum: Element { return reduce(0, +) }
    var mean: Element { return isEmpty ? 0 : sum / Element(count) }
    
    var variance: Element {
        let mean = self.mean
        let squareDiffs = self.map { value -> Element in
            let diff = value - mean
            return diff * diff
        }
        return squareDiffs.mean
    }
    
    var standardDeviation: Element { return variance.squareRoot() }

}

extension Comparable {
    
    public mutating func clamp(min: Self, max: Self) {
        if self < min { self = min }
        if self > max { self = max }
    }
    
    public func clamped(min: Self, max: Self) -> Self {
        var result = self
        if result < min { result = min }
        if result > max { result = max }
        return result
    }
}
