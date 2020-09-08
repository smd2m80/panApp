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


class SecondViewController: UIViewController, WKUIDelegate {

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
        
        // UITapGestureRecognizerでタップイベントを取るようにする
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1

        // このときUIGestureRecognizerDelegateに準拠したオブジェクトを設定する
        tapRecognizer.delegate = self
        webView.addGestureRecognizer(tapRecognizer)
        
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
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer){
//        NSLog("Tap")
        
        let accZ200msMin = accZ.suffix(20).min() ?? 0
                    print(accZ200msMin)

                    if (accZ200msMin < -0.15){
                        let activeUrl: URL? = self.webView.url
                        let url = activeUrl?.absoluteString
//                        print(url!)
                        UIPasteboard.general.string = url
//                        alert(title: "コピーしました", message: "")
        }
    }
    
    

    //アラート
    func alert(title: String, message: String)  {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
}


extension SecondViewController: UIGestureRecognizerDelegate {

    // MARK: UIGestureRecognizerDelegate

    // このgestureRecognizerをオーバーライドしてtrueにしないとサブビューではTapイベントを検知できない
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
