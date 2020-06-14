//
//  AppDelegate.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/20.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

#if !targetEnvironment(macCatalyst)
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        swizzleShouldInheritScreenScaleAsContentScaleFactor()

        #if !targetEnvironment(macCatalyst)
        #if !DEBUG
        MSAppCenter.start("4c46cd7d-ea97-452b-920c-4328ac062db3", withServices:[
            MSAnalytics.self,
            MSCrashes.self
        ])
        #endif
        #endif

        window = UIWindow()
        let vc = MainViewControler()

        window?.rootViewController = vc
        window?.makeKeyAndVisible()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        urlToRun = url
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        let core = CelestiaAppCore.shared
        if core.isInitialized {
            core.storeUserDefaults()
        }
    }
}

extension AppDelegate {
    private func swizzleShouldInheritScreenScaleAsContentScaleFactor() {
        let clazz = MGLKView.self
        let selector = NSSelectorFromString("_shouldInheritScreenScaleAsContentScaleFactor")
        guard let method = class_getInstanceMethod(clazz, selector) else { return }
        class_replaceMethod(clazz, selector, imp_implementationWithBlock({ (_: MGLKView) -> Bool in
            return false
        } as @convention(block) (MGLKView) -> Bool), method_getTypeEncoding(method))
    }
}

