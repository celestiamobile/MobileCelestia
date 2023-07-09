//
// CelestiaXRApp.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaFoundation
import CelestiaUI
import CelestiaXRCore
import CompositorServices
import Observation
import SwiftUI

struct MetalLayerConfiguration: CompositorLayerConfiguration {
    func makeConfiguration(capabilities: LayerRenderer.Capabilities,
                           configuration: inout LayerRenderer.Configuration) {
        configuration.layout = .dedicated
        configuration.isFoveationEnabled = false
        configuration.colorFormat = .bgr10a2Unorm
    }
}

extension ResourceManager: ObservableObject {}

@main
struct CelestiaXRApp: App {
    private let bundle: Bundle
    private let defaultDataDirectoryURL: URL
    private let defaultConfigFileURL: URL
    private let userDefaults: UserDefaults
    private let browserItemStore = BrowserItemStore()
    private let renderer: XRRenderer
    private let interactionManager = InteractionManager()
    private let userDirectory: URL
    private let resourceManager: ResourceManager

    init() {
        let userDirectory = URL.documentsDirectory.appending(component: "CelestiaResources")
        let bundle = Bundle.app
        let defaults = UserDefaults.standard
        let defaultDataDirectoryURL = bundle.url(forResource: "CelestiaResources", withExtension: nil)!
        let defaultConfigFileURL = defaultDataDirectoryURL.appending(component: "celestia.cfg")
        userDefaults = defaults
        let extraDirectoryURL = userDirectory.appending(component: "extras")
        renderer = {
            let defaultConfigPlistPath = bundle.path(forResource: "defaults", ofType: "plist")
            let fontDirectoryURL = bundle.url(forResource: "Fonts", withExtension: nil)!
            let (defaultFonts, otherFonts) = FontCollection.fontsInDirectory(fontDirectoryURL)
            return XRRenderer(
                renderer: Renderer(
                    resourceFolderPath: defaultDataDirectoryURL.path(percentEncoded: false),
                    configFilePath: defaultConfigFileURL.path(percentEncoded: false),
                    extraDirectories: [extraDirectoryURL.path(percentEncoded: false)],
                    userDefaults: defaults,
                    appDefaultsPath:defaultConfigPlistPath,
                    defaultFonts: defaultFonts,
                    otherFonts: otherFonts
                )
            )
        }()
        self.bundle = bundle
        self.defaultDataDirectoryURL = defaultDataDirectoryURL
        self.defaultConfigFileURL = defaultConfigFileURL
        self.userDirectory = userDirectory
        self.resourceManager = ResourceManager(extraAddonDirectory: extraDirectoryURL)
    }

    var body: some Scene {
        WindowGroup {
            StartUpView()
                .environmentObject(renderer)
                .environmentObject(interactionManager)
        }

        Group {
            WindowGroup(id: "BrowserWindow") {
                BrowserView()
                    .environmentObject(renderer)
                    .environmentObject(browserItemStore)
            }

            WindowGroup(id: "SubsystemWindow", for: UUID.self) { $id in
                SubsystemBrowserWindow(id: id ?? UUID())
                    .environmentObject(renderer)
                    .environmentObject(browserItemStore)
            }
        }

        Group {
            WindowGroup(id: "AddonManagementView") {
                AddonManagementView()
                    .environmentObject(renderer)
                    .environmentObject(resourceManager)
            }

            WindowGroup(id: "AddonWindow", for: String.self) { $id in
                AddonWindow(id: id ?? "")
                    .environmentObject(renderer)
                    .environmentObject(resourceManager)
            }

            WindowGroup(id: "AddonCategoriesView") {
                AddonCategoriesView()
                    .environmentObject(renderer)
                    .environmentObject(resourceManager)
            }
        }

        Group {
            WindowGroup(id: "InfoWindow") {
                InfoWindow()
                    .environmentObject(renderer)
                    .environmentObject(browserItemStore)
            }

            WindowGroup(id: "MainSearch") {
                MainSearch()
                    .environmentObject(renderer)
            }

            WindowGroup(id: "GoTo") {
                GoToView()
                    .environmentObject(renderer)
            }

            WindowGroup(id: "EclipseFinder") {
                EclipseFinder()
                    .environmentObject(renderer)
            }

            WindowGroup(id: "CameraControl") {
                CameraControlView()
                    .environmentObject(renderer)
            }

            WindowGroup(id: "FavoriteView") {
                FavoriteView(userDirectory: userDirectory)
                    .environmentObject(renderer)
            }

            WindowGroup(id: "SettingsView") {
                SettingsView(userDefault: userDefaults, bundle: bundle, defaultDataDirectory: defaultDataDirectoryURL, defaultConfigFile: defaultConfigFileURL)
                    .environmentObject(renderer)
            }
        }

        Group {
            WindowGroup(id: "HelpView") {
                HelpView()
                    .environmentObject(renderer)
                    .environmentObject(resourceManager)
            }
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            CompositorLayer(configuration: MetalLayerConfiguration()) { layerRenderer in
                renderer.startRendering(with: layerRenderer)
                layerRenderer.onSpatialEvent = { collection in
                    renderer.enqueue(events: collection)
                }
            }
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
