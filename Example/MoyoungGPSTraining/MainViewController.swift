//
//  MainViewController.swift
//  MoyoungGPSTraining_Example
//
//  Created by 李然 on 2023/8/9.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    @IBAction func startClick(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "MapViewController") else { return }
        show(vc, sender: self)
    }
    
    @IBAction func distanceClick(_ sender: Any) {
        guard let count = self.textField.text, let c = Double(count) else { return }
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController  else { return }
        vc.goalType = .distance(goal: c)
        show(vc, sender: self)
    }
    
    @IBAction func timeClick(_ sender: Any) {
        guard let count = self.textField.text, let c = Double(count) else { return }
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController  else { return }
        vc.goalType = .time(goal: c)
        show(vc, sender: self)
    }
    
    @IBAction func speedClick(_ sender: Any) {
        guard let count = self.textField.text, let c = Double(count) else { return }
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController  else { return }
        vc.goalType = .pace(goal: c)
        show(vc, sender: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        self.textField.resignFirstResponder()
    }
}
