//
//  GPSTrainingLine.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 2023/8/23.
//

import Foundation
import CoreLocation

public class GPSTrainingLine {
    public let id: UUID
    public private(set) var locations: [CLLocation] = []
    
    init() {
        self.id = UUID()
    }
    
    public func add(location: CLLocation) {
        self.locations.append(location)
    }
}
