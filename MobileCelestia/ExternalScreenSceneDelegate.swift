//
// PanelSceneDelegate.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaFoundation
import CelestiaUI
import UIKit

#if !targetEnvironment(macCatalyst)
let newScreenConnectedNotificationName = Notification.Name("NewScreenConnectedNotification")
let screenDisconnectedNotificationName = Notification.Name("ScreenDisconnectedNotification")
let windowSceneUserInfoKey: String = "WindowSceneUserInfoKey"

class ExternalScreenSceneDelegate: CommonSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        NotificationCenter.default.post(name: newScreenConnectedNotificationName, object: windowScene)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        NotificationCenter.default.post(name: screenDisconnectedNotificationName, object: windowScene)
    }
}
#endif
