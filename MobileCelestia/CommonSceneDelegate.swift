//
// CommonSceneDelegate.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
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
