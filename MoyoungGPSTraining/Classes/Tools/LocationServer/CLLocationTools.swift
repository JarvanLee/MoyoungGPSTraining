//
//  CLLocationTools.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/23.
//

import Foundation
import CoreLocation

extension Array where Element: CLLocation {
    public var distance: CLLocationDistance {
        var distance: CLLocationDistance = 0
        var previousLocation: CLLocation?
        for location in self {
            if let previous = previousLocation {
                distance += previous.distance(from: location)
            }
            previousLocation = location
        }
        return distance
    }
}

public extension CLLocation {
    func countryCodeUserWGS(handler: ((_ isWGS: Bool) -> Void)?) {
        self.countryCode { countryCode in
            let isWGS = countryCode == "CN" || countryCode == "HK" || countryCode == "MO"
            handler?(isWGS)
        }
    }
    
    func countryCode(handler: ((_ countryCode: String?) -> Void)?) {
        CLGeocoder().reverseGeocodeLocation(self) { (placemarks: [CLPlacemark]?, error: Error?) in
            // 有可能为空或失败
            guard let placemark = placemarks?.first, error == nil else {
                return
            }
            handler?(placemark.isoCountryCode)
        }
    }
}


extension CLLocationCoordinate2D {
    public func transformFormWGSToGCJ() -> CLLocationCoordinate2D {
        var gcjLoc = CLLocationCoordinate2D()
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
    
    public func transformLat(x: Double, y: Double) -> Double {
        let tempSqrtLat = 0.2 * sqrt(abs(x))
        var lat: Double = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + tempSqrtLat
        lat += (20.0 * sin(6.0 * x * self.π) + 20.0 * sin(2.0 * x * self.π)) * 2.0 / 3.0
        lat += (20.0 * sin(y * self.π) + 40.0 * sin(y / 3.0 * self.π)) * 2.0 / 3.0
        lat += (160.0 * sin(y / 12.0 * self.π) + 320 * sin(y * self.π / 30.0)) * 2.0 / 3.0
        return lat
    }
    
    public func transformLon(x: Double, y: Double) -> Double {
        let tempSqrtLon = 0.1 * sqrt(abs(x))
        var lon = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + tempSqrtLon
        lon += (20.0 * sin(6.0 * x * self.π) + 20.0 * sin(2.0 * x * self.π)) * 2.0 / 3.0
        lon += (20.0 * sin(x * self.π) + 40.0 * sin(x / 3.0 * self.π)) * 2.0 / 3.0
        lon += (150.0 * sin(x / 12.0 * self.π) + 300.0 * sin(x / 30.0 * self.π)) * 2.0 / 3.0
        return lon
    }
    
    fileprivate var π: Double {
        return Double.pi
    }
    
    fileprivate var ee: Double {
        return 0.00669342162296594323
    }

    fileprivate var a: Double {
        return 6378245.0
    }
}
