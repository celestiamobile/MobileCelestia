//
// AppDelegate.swift
//
// Copyright © 2024 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    static weak var sharedDelegate: AppDelegate?

    var urlManager: URLManager?

    func application(_ application: UIApplication, configurationForConnecting
        connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        Self.sharedDelegate = self
        let config = UISceneConfiguration(name: nil,
            sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}
