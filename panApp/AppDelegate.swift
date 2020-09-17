//
//  AppDelegate.swift
//  panApp
//
//  Created by smd on 2020/08/18.
//  Copyright © 2020 smd. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current()
        .requestAuthorization(options: [.badge, .sound, .alert], completionHandler: { (granted, error) in
            // 許可されない場合は、アプリを終了する
            if !granted {
                let alert = UIAlertController(
                    title: "エラー",
                    message: "プッシュ通知が拒否されています。設定から有効にしてください。",
                    preferredStyle: .alert
                )
                
                // 終了処理
                let closeAction = UIAlertAction(title: "閉じる", style: .default) { _ in exit(1) }
                alert.addAction(closeAction)
                
                // ダイアログを表示
                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        })
        
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

