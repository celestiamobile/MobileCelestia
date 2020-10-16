//
// MainSceneDelegate.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

@available(iOS 13, *)
class MainSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        #if targetEnvironment(macCatalyst)
        windowScene.titlebar?.autoHidesToolbarInFullScreen = true
        #endif
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        let vc = MainViewControler(initialURL: connectionOptions.urlContexts.first?.url)
        if let userActivity = connectionOptions.userActivities.first {
            AppDelegate.handleUserActivity(userActivity)
        }
        window.rootViewController = vc

        self.window = window
        window.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        AppDelegate.handleUserActivity(userActivity)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        NotificationCenter.default.post(name: newURLOpenedNotificationName, object: nil, userInfo: [newURLOpenedNotificationURLKey : url])
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        exit(0)
    }
}
