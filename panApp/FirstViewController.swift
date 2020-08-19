//
//  FirstViewController.swift
//  panApp
//
//  Created by smd on 2020/08/18.
//  Copyright © 2020 smd. All rights reserved.
//

import UIKit
import CoreMotion
import simd

class FirstViewController: UIViewController {
    @IBOutlet var imageView:UIImageView!
    
    let motionManager = CMMotionManager()
    var attitude : [CMAttitude] = []
    var gyro : [CMRotationRate] = []
    var accZ : [Double] = []
    var cFLAG = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startSensorUpdates(intervalSeconds: 0.01) // 100Hz
        
        let screenWidth = view.frame.size.width
        let screenHeight = view.frame.size.height

        let image:UIImage = UIImage(named:"Kopernikus01")!
        imageView.image = image
        imageView.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
        self.view.addSubview(imageView)
        imageView.isHidden = true

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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//           let touch = touches.first!
        let accZ200msMin = accZ.suffix(10).min() ?? 0
//        print(accZ.suffix(20))

        if (accZ200msMin < -0.15){
            cFLAG = true
            imageView.isHidden = false
        }
       }
    
    override func touchesEnded(_ touches: Set<UITouch>, with
        event: UIEvent?) {
        imageView.isHidden = true
    }
    
}

