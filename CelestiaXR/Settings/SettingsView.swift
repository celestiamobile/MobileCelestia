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
        let shadowMapSizeFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter
        }()

        let shadowMapSizeOptions: [AssociatedPreferenceSelectionItem.Option] = [0, 1024, 2048, 4096, 8192].map { size in
            .init(name: shadowMapSizeFormatter.string(from: size), value: size)
        }

        var baseAdvancedItems = [
            SettingItem(
                name: CelestiaString("Anti-aliasing", comment: ""),
                associatedItem: .prefSwitch(item:
                    AssociatedPreferenceSwitchItem(key: .msaa, defaultOn: false)
                )
            ),
            SettingItem(
                name: CelestiaString("Foveated Rendering", comment: ""),
                associatedItem: .prefSwitch(item:
                    AssociatedPreferenceSwitchItem(key: .foveatedRendering, defaultOn: false)
                )
            ),
            SettingItem(
                name: CelestiaString("Shadow Resolution", comment: "Resolution of shadow maps"),
                subtitle: CelestiaString("A value of 0 disables self-shadowing. Higher values produce sharper shadows at a greater performance cost.", comment: "Shadow resolution setting footnote"),
                associatedItem: .prefSelection(
                    item: AssociatedPreferenceSelectionItem(key: .shadowMapSize, options: shadowMapSizeOptions, defaultOption: 0)
                )
            ),
        ]

        if #available(visionOS 2.0, *) {
            baseAdvancedItems.append(SettingItem(
                name: CelestiaString("Passthrough", comment: "Mixed immersion / passthrough toggle"),
                associatedItem: .prefSwitch(item:
                    AssociatedPreferenceSwitchItem(key: .mixedImmersion, defaultOn: false)
                )
            ))
        }

        let settings = [
            displaySettings(),
            rendererSettings(extraItems: [
                SettingItem(
                    name: CelestiaString("Advanced", comment: "Advanced setting items"),
                    associatedItem: .common(item:
                        AssociatedCommonItem(
                            title: CelestiaString("Advanced", comment: "Advanced setting items"),
                            sections: [
                                .init(header: nil, rows: baseAdvancedItems, footer: CelestiaString("Configuration will take effect after a restart.", comment: "Change requires a restart")),
                                outputRenderSettings(),
                            ]
                        )
                    )
                ),
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
