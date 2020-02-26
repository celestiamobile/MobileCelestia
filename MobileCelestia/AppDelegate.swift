//
//  AppDelegate.swift
//  MobileCelestia
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

        window = UIWindow()
        let vc = MainViewControler()

        window?.rootViewController = vc
        window?.makeKeyAndVisible()

        FileManager.default.changeCurrentDirectoryPath(defaultDataDirectory.path)
        CelestiaAppCore.setLocaleDirectory(defaultDataDirectory.path + "/locale")

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let core = CelestiaAppCore.shared
        if core.isInitialized {
            if !url.startAccessingSecurityScopedResource() { return false }
            core.runScript(at: url.path)
            url.stopAccessingSecurityScopedResource()
        } else {
            startingScriptURL = url
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        let core = CelestiaAppCore.shared
        if core.isInitialized {
            core.storeUserDefaults()
        }
    }
}

