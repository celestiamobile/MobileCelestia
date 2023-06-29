// SceneDelegate.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaFoundation
import SwiftUI
import UIKit

@Observable class URLManager {
    var savedURL: AppURL?
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let appURL = AppURL.from(userActivity: userActivity) else { return }
        AppDelegate.sharedDelegate?.urlManager?.savedURL = appURL
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        guard let appURL = AppURL.from(urlContext: urlContext) else { return }
        AppDelegate.sharedDelegate?.urlManager?.savedURL = appURL
    }
}
