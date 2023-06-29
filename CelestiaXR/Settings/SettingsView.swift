//
// SettingsView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import SwiftUI

struct SettingsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = SettingsCoordinatorController

    @Environment(XRRenderer.self) private var renderer
    private let userDefaults: UserDefaults
    private let bundle: Bundle
    private let defaultDataDirectory: URL
    private let defaultConfigFile: URL

    init(userDefault: UserDefaults, bundle: Bundle, defaultDataDirectory: URL, defaultConfigFile: URL) {
        self.userDefaults = userDefault
        self.bundle = bundle
        self.defaultDataDirectory = defaultDataDirectory
        self.defaultConfigFile = defaultConfigFile
    }

    func makeUIViewController(context: Context) -> SettingsCoordinatorController {

        let settings = [
            displaySettings(),
            rendererSettings(extraItems: []),
            advancedSettings(extraItems: [gameControllerItem]),
            miscSettings(),
        ]

        return SettingsCoordinatorController(
            core: renderer.appCore,
            executor: renderer,
            userDefaults: userDefaults,
            bundle: bundle,
            defaultDataDirectory: defaultDataDirectory,
            settings: settings,
            dataLocationContext: DataLocationSettingContext(
                userDefaults: userDefaults,
                dataDirectoryUserDefaultsKey: "DUMMY",
                configFileUserDefaultsKey: "DUMMY",
                defaultDataDirectoryURL: defaultDataDirectory,
                defaultConfigFileURL: defaultConfigFile
            ),
            actionHandler: { _ in }
        ) { viewController, title, format in
            return await viewController.getDateInput(title, format: format)
        } textInputHandler: { viewController, title, keyboardType in
            return await viewController.getTextInput(title, keyboardType: keyboardType)
        } rendererInfoProvider: {
            return await renderer.get { $0.renderInfo }
        }
    }

    func updateUIViewController(_ uiViewController: SettingsCoordinatorController, context: Context) {
    }
}
