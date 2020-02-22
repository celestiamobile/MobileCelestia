//
//  AppDelegate.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/20.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        FileManager.default.changeCurrentDirectoryPath(defaultDataDirectory.path)
        CelestiaAppCore.setLocaleDirectory(defaultDataDirectory.path + "/locale")

        return true
    }

}

