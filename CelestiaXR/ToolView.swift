//
// ToolView.swift
//
// Copyright © 2024 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import SwiftUI

struct ToolView: View {
    @Environment(WindowManager.self) private var windowManager

    private let userDefaults: UserDefaults
    private let bundle: Bundle
    private let defaultDataDirectory: URL
    private let defaultConfigFile: URL
    private let userDirectory: URL
    private let resourceManager: ResourceManager
    private let requestHandler: RequestHandler
    private let assetProvider: AssetProvider

    init(userDefault: UserDefaults, bundle: Bundle, defaultDataDirectory: URL, defaultConfigFile: URL, userDirectory: URL, resourceManager: ResourceManager, requestHandler: RequestHandler, assetProvider: AssetProvider) {
        self.userDefaults = userDefault
        self.bundle = bundle
        self.defaultDataDirectory = defaultDataDirectory
        self.defaultConfigFile = defaultConfigFile
        self.userDirectory = userDirectory
        self.resourceManager = resourceManager
        self.requestHandler = requestHandler
        self.assetProvider = assetProvider
    }

    var body: some View {
        Group {
            switch windowManager.tool {
            case .none:
                Text(CelestiaString("No tool is selected", comment: ""))
            case .browser:
                BrowserView(assetProvider: assetProvider)
            case .search:
                MainSearch()
            case .installedAddons:
                AddonManagementView(resourceManager: resourceManager, requestHandler: requestHandler)
            case .downloadAddons:
                AddonCategoriesView(resourceManager: resourceManager, requestHandler: requestHandler, category: nil)
            case .goTo:
                GoToView()
            case .eclipseFinder:
                EclipseFinder()
            case .cameraControl:
                CameraControlView()
            case .favorites:
                FavoriteView(userDirectory: userDirectory)
            case .currentTime:
                TimeSettingsView()
            case .settings:
                SettingsView(userDefault: userDefaults, bundle: bundle, defaultDataDirectory: defaultDataDirectory, defaultConfigFile: defaultConfigFile, assetProvider: assetProvider)
            case .help:
                HelpView(resourceManager: resourceManager, requestHandler: requestHandler, assetProvider: assetProvider)
            }
        }
    }
}

