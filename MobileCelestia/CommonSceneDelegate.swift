// CommonSceneDelegate.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaFoundation
import UIKit

class CommonSceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        AppDelegate.handleUserActivity(userActivity)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        NotificationCenter.default.post(name: newURLOpenedNotificationName, object: nil, userInfo: [
            newURLOpenedNotificationURLKey: UniformedURL(url: urlContext.url, securityScoped: urlContext.url.isFileURL && urlContext.options.openInPlace)
        ])
    }
}
