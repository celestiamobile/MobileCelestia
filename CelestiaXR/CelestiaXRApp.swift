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

@main
struct CelestiaXRApp: App {
    private var browserItemStore = BrowserItemStore()
    private var renderer = XRRenderer(renderer: Renderer(resourceFolderPath: Bundle.main.path(forResource: "CelestiaResources", ofType: nil)!, configFilePath: "celestia.cfg", userDefaultsPath: Bundle.main.path(forResource: "defaults", ofType: "plist")))

    var body: some Scene {
        WindowGroup {
            StartUpView()
                .environmentObject(renderer)
        }

        WindowGroup(id: "InfoWindow") {
            InfoWindow()
                .environmentObject(renderer)
                .environmentObject(browserItemStore)
        }

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
