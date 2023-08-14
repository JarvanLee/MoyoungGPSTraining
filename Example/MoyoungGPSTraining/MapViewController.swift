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
        let provider = GpsProvider(traningType: .gps_Run)
        NotificationCenter.default.addObserver(forName: Notification.Name("Step"), object: nil, queue: nil) { notication in
            if let step = notication.object as? Int {
                provider.stepsHandler?(step)
            }
        }
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
            goalSubText = "米"
        case .distance(let goal):
            distanceLabel = goalLabel
            distanceUnitLable = nil
            timeLabel = info1Label
            timeUnitLabel = info1SubLabel
            paceLabel = info2Label
            paceUnitLabel = info2SubLabel
            kcalLabel = info3Label
            kcalUnitLable = info3SubLabel
            
            goalSubText = "/ \(goal)" + " " + "米"
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
        distanceUnitLable?.text = "米"
        timeLabel?.text = "00:00:00"
        timeUnitLabel?.text = "总时间"
        paceLabel?.text = "00’00’’"
        paceUnitLabel?.text = "配速"
        kcalLabel?.text = "0"
        kcalUnitLable?.text = "千卡"
    }
    
    @IBAction func gpsClick(_ sender: Any) {
        runner.setProvider(GpsProvider(traningType: .gps_Run))
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
        
        distanceLabel?.text = "\(run.totalDistance)"
        
        let runTime = Int(run.totalValidDuration)
        let timeStr = String(format: "%02d:%02d:%02d", runTime / 3600, (runTime / 60)%60, runTime % 60)
        timeLabel?.text = timeStr
    }
    
    func runner(_ runner: Runner, didUpdateGoalProgress progress: Progress) {
        progressView.progress = Float(progress.fractionCompleted)
    }
    
    func runner(_ runner: Runner, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last {
            self.coordinateArray.append(last.coordinate)
            updatePath()
        }
    }
    
    func runner(_ runner: Runner, didUpdateHeadingAngle angle: Double) {
        self.userAnnotationView?.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
    }
    
    func updatePath() {
        let overlays = self.mapView.overlays
        self.mapView.removeOverlays(overlays)
        
        let polyline = MKPolyline(coordinates: &self.coordinateArray, count: Int(UInt(self.coordinateArray.count)))
        self.mapView.add(polyline)
        
        if let lastCoord = self.coordinateArray.last {
            self.mapView.centerCoordinate = lastCoord
        }
    }
}
