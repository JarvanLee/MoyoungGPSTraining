//
//  MapViewController.swift
//  MoyoungGPSTraining
//
//  Created by 李然 on 08/08/2023.
//  Copyright (c) 2023 李然. All rights reserved.
//

import UIKit
import MapKit
import MoyoungGPSTraining

let kScreenHeight = UIScreen.main.bounds.height
let kScreenWidth  = UIScreen.main.bounds.width

class MapViewController: UIViewController {
    
    var goalType: RunGoalType = .none
    
    var distanceLabel: UILabel?
    var distanceUnitLable: UILabel?
    var timeLabel: UILabel?
    var timeUnitLabel: UILabel?
    var paceLabel: UILabel?
    var paceUnitLabel: UILabel?
    var kcalLabel: UILabel?
    var kcalUnitLable: UILabel?
    
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var info1Label: UILabel!
    @IBOutlet weak var info2Label: UILabel!
    @IBOutlet weak var info3Label: UILabel!
    
    @IBOutlet weak var goalSubLabel: UILabel!
    @IBOutlet weak var info1SubLabel: UILabel!
    @IBOutlet weak var info2SubLabel: UILabel!
    @IBOutlet weak var info3SubLabel: UILabel!
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var mapView: MKMapView!
    
    var userAnnotationView: MKAnnotationView?
    
    let runner = Runner()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        runner.delegate = self
        let provider = GpsProvider()
        NotificationCenter.default.addObserver(forName: Notification.Name("Step"), object: nil, queue: nil) { notication in
            if let step = notication.object as? Int {
                provider.stepsHandler?(step)
            }
        }
        runner.setProvider(PedometerProvider())
        runner.setProvider(provider)
        runner.goal = self.goalType
     
        setupMapView()
        setupInfoLabel()
    }
    
    private func setupMapView() {
        self.mapView.delegate = self
        self.mapView.mapType = .standard
        self.mapView.showsCompass = true
        self.mapView.showsUserLocation = true
        self.mapView.isRotateEnabled = true
        self.mapView.setUserTrackingMode(.follow, animated: true)
        //设置地图比例
        let location = self.mapView.userLocation
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, CLLocationDistance(exactly: 500)!, CLLocationDistance(exactly: 500)!)
        self.mapView.region = region
        self.mapView.setRegion(self.mapView.regionThatFits(region), animated: false)
    }
    
    func setupInfoLabel(){
        var goalSubText = ""
        switch self.goalType{
        case .none:
            distanceLabel = goalLabel
            distanceUnitLable = nil
            timeLabel = info1Label
            timeUnitLabel = info1SubLabel
            paceLabel = info2Label
            paceUnitLabel = info2SubLabel
            kcalLabel = info3Label
            kcalUnitLable = info3SubLabel
            goalSubText = "千米"
        case .distance(let goal):
            distanceLabel = goalLabel
            distanceUnitLable = nil
            timeLabel = info1Label
            timeUnitLabel = info1SubLabel
            paceLabel = info2Label
            paceUnitLabel = info2SubLabel
            kcalLabel = info3Label
            kcalUnitLable = info3SubLabel
            
            goalSubText = "/ \(String(format: "%.2f",goal))" + " " + "千米"
        case .time(let goal):
            distanceLabel = info1Label
            distanceUnitLable = info1SubLabel
            timeLabel = goalLabel
            timeUnitLabel = nil
            paceLabel = info2Label
            paceUnitLabel = info2SubLabel
            kcalLabel = info3Label
            kcalUnitLable = info3SubLabel
            
            let goalHour = Int(goal / 60)
            let goalMinuter = Int(goal)%60
            goalSubText = "/ \(String(format: "%02d",goalHour))" + ":\(String(format: "%02d",goalMinuter))" + ":00"
        case .pace(let goal):
            paceLabel = goalLabel
            paceUnitLabel = nil
            timeLabel = info1Label
            timeUnitLabel = info1SubLabel
            distanceLabel = info2Label
            distanceUnitLable = info2SubLabel
            kcalLabel = info3Label
            kcalUnitLable = info3SubLabel
            
            let goalStr = String(format: "%.2f", goal)
            let paces = goalStr.components(separatedBy: ".")
            if let min = paces.first, let second = paces.last {
                goalSubText = String(format: "%02d’%@’’", Int(Double(min)!),second)
            } else {
                goalSubText = "/ \(String(format: "%02.0f",goal))" + "’00’’"
            }
        case .calorise(let goal):
            kcalLabel = goalLabel
            kcalUnitLable = nil
            timeLabel = info1Label
            timeUnitLabel = info1SubLabel
            paceLabel = info2Label
            paceUnitLabel = info2SubLabel
            distanceLabel = info3Label
            distanceUnitLable = info3SubLabel
            
            goalSubText = "/ \(String(format: "%.0f",goal))" + " " + "千卡"
        }
        goalSubLabel.text = goalSubText
        
        distanceLabel?.text = "0.00"
        distanceUnitLable?.text = "公里"
        timeLabel?.text = "00:00:00"
        timeUnitLabel?.text = "总时间"
        paceLabel?.text = "00’00’’"
        paceUnitLabel?.text = "配速"
        kcalLabel?.text = "0"
        kcalUnitLable?.text = "千卡"
    }
    
    @IBAction func gpsClick(_ sender: Any) {
        runner.setProvider(GpsProvider())
    }
    
    @IBAction func jbqClick(_ sender: Any) {
        runner.setProvider(PedometerProvider(isMapRequird: true))
    }
    
    @IBAction func startClick(_ sender: Any) {
        runner.start()
    }
    
    @IBAction func pauseClick(_ sender: Any) {
        runner.pause()
    }
    
    @IBAction func stopClick(_ sender: Any) {
        runner.stop()
    }
    
    var coordinateArray: [CLLocationCoordinate2D] = []
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "User"

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil{
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        if let image = UIImage(named: "ic_gps_exercise_map_point"){
            annotationView?.image = image
            self.userAnnotationView = annotationView
            annotationView?.centerOffset = CGPoint(x: 0, y: -image.size.height/3)
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer()
        }

        let polylineView = MKPolylineRenderer(overlay: polyline)
        polylineView.lineWidth = 6.0
        polylineView.strokeColor = UIColor(red: 74 / 255.0, green: 144 / 255.0, blue: 226 / 255.0, alpha: 1.0)

        return polylineView
    }
}

extension MapViewController: RunnerDelegate {
    
    func runner(_ runner: Runner, didUpdateRun run: Run) {
        paceLabel?.text = "\(run.getAverageSpeed)"
        
        let km = Double(Double(run.totalDistance)*10/1000)/10.0
        distanceLabel?.text = String(format: "%.2f",km)
        
        let runTime = Int(run.totalValidDuration)
        let timeStr = String(format: "%02d:%02d:%02d", runTime / 3600, (runTime / 60)%60, runTime % 60)
        timeLabel?.text = timeStr
    }
    
    func runner(_ runner: Runner, didUpdateGoalProgress progress: Progress) {
        progressView.progress = Float(progress.fractionCompleted)
    }
    
    func runner(_ runner: Runner, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last {
            let coordinate = CoordinateTool.transformFormWGSToGCJ(last.coordinate)
            self.coordinateArray.append(coordinate)
            updatePath()
        }
    }
    
    func runner(_ runner: Runner, didUpdateLocationHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0{
            return
        }else {
            let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
            let rotation = heading/180 * .pi
            self.userAnnotationView?.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
        }
    }
    
    func updatePath() {
        let overlays = self.mapView.overlays
        self.mapView.removeOverlays(overlays)
        
        let polyline = MKPolyline(coordinates: &self.coordinateArray, count: Int(UInt(self.coordinateArray.count)))
        self.mapView.add(polyline)
        
        let lastCoord = self.coordinateArray[self.coordinateArray.count - 1]
        self.mapView.centerCoordinate = lastCoord
    }
}

enum CoordinateTool {

    public static let π: Double = CGFloat.pi
    public static let ee: Double = 0.00669342162296594323
    public static let a: Double = 6378245.0
    
    public static func transformFormWGSToGCJ(_ wgsLoc: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        var gcjLoc: CLLocationCoordinate2D = CLLocationCoordinate2D()
        if isLocationOutOfChina(wgsLoc) {
            gcjLoc = wgsLoc
        } else {
            var adjustLat: Double = transformLat(x: wgsLoc.longitude - 105.0, y: wgsLoc.latitude - 35.0)
            var adjustLon: Double = transformLon(x: wgsLoc.longitude - 105.0, y: wgsLoc.latitude - 35.0)
            let radLat = wgsLoc.latitude / 180.0 * π
            var magic = sin(radLat)
            magic = 1 - ee * magic * magic
            let sqrtMagic: Double = sqrt(magic)
            adjustLat = (adjustLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * π)
            adjustLon = (adjustLon * 180.0) / (a / sqrtMagic * cos(radLat) * π)
            gcjLoc.longitude = wgsLoc.longitude + adjustLon
            gcjLoc.latitude = wgsLoc.latitude + adjustLat
        }
        return gcjLoc
    }

    public static func transformLat(x: Double, y: Double) -> Double {
        let tempSqrtLat = 0.2 * sqrt(abs(x))
        var lat: Double = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + tempSqrtLat
        lat += (20.0 * sin(6.0 * x * π) + 20.0 * sin(2.0 * x * π)) * 2.0 / 3.0
        lat += (20.0 * sin(y * π) + 40.0 * sin(y / 3.0 * π)) * 2.0 / 3.0
        lat += (160.0 * sin(y / 12.0 * π) + 320 * sin(y * π / 30.0)) * 2.0 / 3.0
        return lat
    }

    public static func transformLon(x: Double, y: Double) -> Double {
        let tempSqrtLon = 0.1 * sqrt(abs(x))
        var lon: Double = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + tempSqrtLon
        lon += (20.0 * sin(6.0 * x * π) + 20.0 * sin(2.0 * x * π)) * 2.0 / 3.0
        lon += (20.0 * sin(x * π) + 40.0 * sin(x / 3.0 * π)) * 2.0 / 3.0
        lon += (150.0 * sin(x / 12.0 * π) + 300.0 * sin(x / 30.0 * π)) * 2.0 / 3.0
        return lon
    }

    public static func isLocationOutOfChina(_ location: CLLocationCoordinate2D) -> Bool {
        if location.longitude<72.004 || location.longitude>137.8347 || location.latitude<0.8293 || location.latitude>55.8271 {
            return true
        }
        return false
    }

}
