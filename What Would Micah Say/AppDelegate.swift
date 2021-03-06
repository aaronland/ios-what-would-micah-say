//
//  AppDelegate.swift
//  What Would Micah Say
//
//  Created by asc on 6/11/20.
//  Copyright © 2020 Aaronland. All rights reserved.
//

import UIKit
import OAuthSwift
import Logging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var logger = Logger(label: "info.aaronland.wwms")


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
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

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey  : Any] = [:]) -> Bool {
        
      if url.host == "oauth2" {
        OAuthSwift.handle(url: url)
      }
      return true
    }
}

