//
//  FirstViewController.swift
//  panApp
//
//  Created by smd on 2020/08/18.
//  Copyright © 2020 smd. All rights reserved.
//

import UIKit
import WebKit
import CoreMotion
import simd


class SecondViewController: UIViewController, WKUIDelegate, UIGestureRecognizerDelegate {

    var webView: WKWebView!
    
    let motionManager = CMMotionManager()
    var attitude : [CMAttitude] = []
    var gyro : [CMRotationRate] = []
    var accZ : [Double] = []
    var cFLAG = false

    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        startSensorUpdates(intervalSeconds: 0.01) // 100Hz
        
        super.viewDidLoad()
        let myURL = URL(string:"https://ja.wikipedia.org/wiki/%E3%82%AC%E3%83%AA%E3%83%AC%E3%82%AA%E3%83%BB%E3%82%AC%E3%83%AA%E3%83%AC%E3%82%A4")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        
        // tapセンサー
        let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(SecondViewController.tapped(_:)))
        // このときUIGestureRecognizerDelegateに準拠したオブジェクトを設定する
        tapGesture.delegate = self
        webView.addGestureRecognizer(tapGesture)
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
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//    //           let touch = touches.first!
//            let accZ200msMin = accZ.suffix(10).min() ?? 0
//            print(accZ.suffix(20))
//
//            if (accZ200msMin < -0.15){
////                print("touch")
//                print(self.webView.url ?? "non")
//        }
//
//    }

    @objc func tapped(_ sender: UITapGestureRecognizer){
        print("tap catch")
        if sender.state == .ended {
            
            print("Ttap")
            
            let accZ200msMin = accZ.suffix(10).min() ?? 0
                        print(accZ.suffix(20))

                        if (accZ200msMin < -0.15){
                            print("touch")
                            let activeUrl: URL? = self.webView.url
                            let url = activeUrl?.absoluteString
                            print(url!)
                            alert(title: "コピーしました", message: "")
            }
        }
    }
    
    //アラート
    func alert(title: String, message: String)  {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
}

