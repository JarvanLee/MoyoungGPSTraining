//
//  LocationServer.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/9.
//

import Foundation
import CoreLocation

/*
public class LocationServer: NSObject {
    
    static let shared = LocationServer()
    
    static let distanceFilter: Double = 1.0
    static let GPSHorizontalAccuracy: Double = 20.0
    
    let locationManager = CLLocationManager()
    
    private var locations: [CLLocation] = []
    private var isRunning = false
    
    override init() {
        locationManager.distanceFilter = LocationServer.distanceFilter
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.activityType = .fitness
    }
    
    public func startUpdate() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .restricted, .denied:
            print("notDetermined")
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationManager.delegate = self
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
            self.isRunning = true
        default:
            break
        }
    }
    
    public func pauseUpdate() {
        self.isRunning = false
        self.locationManager.stopUpdatingHeading()
        self.locationManager.stopUpdatingLocation()
    }
    
    public func stopUpdate() {
        self.isRunning = false
        self.locationManager.stopUpdatingHeading()
        self.locationManager.stopUpdatingLocation()
        self.locations = []
    }
}

extension LocationServer: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            addLocation(location)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        NotificationCenter.default.post(name: .locationHeadUpdate, object: newHeading)
    }
    
    private func addLocation(_ location: CLLocation) {
        let accuracy = location.horizontalAccuracy
        NotificationCenter.default.post(name: .gpsAccuracyUpdate, object: accuracy)
        if self.isRunning {
            if isLocationValid(location) {
                locations.append(location)
                NotificationCenter.default.post(name: .locationsUpdate, object: self.locations)
            }
        }
    }
    
    private func isLocationValid( _ location: CLLocation) -> Bool {
        let accuracy = location.horizontalAccuracy
        guard accuracy > 0 && accuracy <= LocationServer.GPSHorizontalAccuracy else {
            return false
        }
        if let lastLocation = locations.last {
            let distance: CLLocationDistance = lastLocation.distance(from: location)
            if distance < LocationServer.distanceFilter {
                return false
            }
        }
        return true
    }
}*/
