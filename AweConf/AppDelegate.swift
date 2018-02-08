//
//  AppDelegate.swift
//  AweConf
//
//  Created by Matteo Crippa on 30/01/2018.
//  Copyright © 2018 Matteo Crippa. All rights reserved.
//

import UIKit
import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // setup push notification
        setupPush(launchOptions)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastUse")
        UserDefaults.standard.synchronize()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastUse")
        UserDefaults.standard.synchronize()
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard
            let url = userActivity.webpageURL,
            let confUrl = url.fragment
        else { return true }
        
        let confId = confUrl.replacingOccurrences(of: "/conference/", with: "")
        // TODO: open conference detail
        
        return true
    }
}

// MARK: - Push Notification
extension AppDelegate {
    func setupPush(_ launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]

        // WARN: Replace 'YOUR_APP_ID' with your OneSignal App ID.
        OneSignal.initWithLaunchOptions(launchOptions,
                appId: "",
                handleNotificationAction: nil,
                settings: onesignalInitSettings)

        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification

        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
        })
    }
}
