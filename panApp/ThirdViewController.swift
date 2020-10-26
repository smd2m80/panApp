//
//  ThirdViewController.swift
//  panApp
//
//  Created by smd on 2020/08/19.
//  Copyright © 2020 smd. All rights reserved.
//

import UIKit
import CoreMotion
import simd

class ThirdViewController: UIViewController {

    @IBOutlet weak var textView: ToucheEventTextView!
    
    let motionManager = CMMotionManager()
    var attitude : [CMAttitude] = []
    var gyro : [CMRotationRate] = []
    var accZ : [Double] = []
    var cFLAG = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startSensorUpdates(intervalSeconds: 0.01) // 100Hz
        textView.isEditable = false
    }
    

    
    func startSensorUpdates(intervalSeconds:Double) {
        if motionManager.isDeviceMotionAvailable{
            motionManager.deviceMotionUpdateInterval = intervalSeconds
            
            // start sensor updates
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(motion:CMDeviceMotion?, error:Error?) in
                self.getMotionData(deviceMotion: motion!)
                
            })
        }
    }
    func getMotionData(deviceMotion:CMDeviceMotion) {
            attitude.append(deviceMotion.attitude)
            gyro.append(deviceMotion.rotationRate)
            accZ.append(deviceMotion.userAcceleration.z)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        DispatchQueue.main.async {
            if self.cFLAG{
                textView.selectAll(self)
            }else{
                // 選択を解除したい
                textView.selectedRange = NSRange()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//           let touch = touches.first!
        let accZ200msMin = accZ.suffix(10).min() ?? 0
//        print(accZ.suffix(20))
        print(accZ200msMin)
        
        if (accZ200msMin > 0){
            cFLAG = true
        }else{
            cFLAG = false
        }
        textViewDidBeginEditing(textView)
        textView.resignFirstResponder()
        
       }


}
