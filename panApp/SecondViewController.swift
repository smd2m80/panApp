//
//  FirstViewController.swift
//  panApp
//
//  Created by smd on 2020/08/18.
//  Copyright © 2020 smd. All rights reserved.
//

import UIKit
import WebKit

class SecondViewController: UIViewController, WKUIDelegate {

    var webView: WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let myURL = URL(string:"https://ja.wikipedia.org/wiki/%E3%82%AC%E3%83%AA%E3%83%AC%E3%82%AA%E3%83%BB%E3%82%AC%E3%83%AA%E3%83%AC%E3%82%A4")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }

}

