// SettingsView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import SwiftUI

struct SettingsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = SettingsCoordinatorController

    @Environment(XRRenderer.self) private var renderer
    private let userDefaults: UserDefaults
    private let bundle: Bundle
    private let defaultDataDirectory: URL
    private let defaultConfigFile: URL
    private let assetProvider: AssetProvider
    private let featureFlags: FeatureFlags

    init(
        userDefault: UserDefaults,
        bundle: Bundle,
        defaultDataDirectory: URL,
        defaultConfigFile: URL,
        assetProvider: AssetProvider,
        featureFlags: FeatureFlags
    ) {
        self.userDefaults = userDefault
        self.bundle = bundle
        self.defaultDataDirectory = defaultDataDirectory
        self.defaultConfigFile = defaultConfigFile
        self.assetProvider = assetProvider
        self.featureFlags = featureFlags
    }

    func makeUIViewController(context: Context) -> SettingsCoordinatorController {
        var xrOutputItems = [
            SettingItem(
                name: CelestiaString("Foveated Rendering", comment: ""),
                associatedItem: .prefSwitch(item:
                    AssociatedPreferenceSwitchItem(key: .foveatedRendering, defaultOn: false)
                )
            ),
        ]

        if #available(visionOS 2.0, *) {
            xrOutputItems.append(SettingItem(
                name: CelestiaString("Passthrough", comment: "Mixed immersion / passthrough toggle"),
                associatedItem: .prefSwitch(item:
                    AssociatedPreferenceSwitchItem(key: .mixedImmersion, defaultOn: false)
                )
            ))
        }

        let settings = [
            displaySettings(),
            rendererSettings(extraItems: [
                rendererQualitySetting(
                    displayItems: [
                        SettingItem(
                            name: CelestiaString("Anti-aliasing", comment: ""),
                            associatedItem: .prefSwitch(
                                item: AssociatedPreferenceSwitchItem(key: .msaa, defaultOn: false)
                            )
                        ),
                    ]
                ),
                outputRenderSetting(extraSections: [
                    .init(
                        header: CelestiaString("XR", comment: "XR output rendering settings"),
                        rows: xrOutputItems,
                        footer: CelestiaString("Configuration will take effect after a restart.", comment: "Change requires a restart")
                    )
                ]),
            ]),
            advancedSettings(extraItems: [gameControllerItem]),
            miscSettings(),
        ]

        return SettingsCoordinatorController(
            core: renderer.appCore,
            executor: renderer,
            userDefaults: userDefaults,
            bundle: bundle,
            featureFlags: featureFlags,
            defaultDataDirectory: defaultDataDirectory,
            settings: settings,
            dataLocationContext: DataLocationSettingContext(
                userDefaults: userDefaults,
                dataDirectoryUserDefaultsKey: "DUMMY",
                configFileUserDefaultsKey: "DUMMY",
                defaultDataDirectoryURL: defaultDataDirectory,
                defaultConfigFileURL: defaultConfigFile,
            ),
            assetProvider: assetProvider,
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
