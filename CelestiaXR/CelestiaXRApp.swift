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
    private let browserItemStore = BrowserItemStore()
    private let renderer: XRRenderer = {
        let resourceFolderPath = Bundle.main.path(forResource: "CelestiaResources", ofType: nil)!
        let defaultConfigPlistPath = Bundle.main.path(forResource: "defaults", ofType: "plist")
        let fontDirectoryPath = Bundle.main.url(forResource: "Fonts", withExtension: nil)!
        let defaultFonts = FontCollection(
            mainFont: Font(path: fontDirectoryPath.appending(component: "NotoSans-Regular.ttf").path(), index: 0, size: 9),
            titleFont: Font(path: fontDirectoryPath.appending(component: "NotoSans-Bold.ttf").path(), index: 0, size: 15),
            normalRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSans-Regular.ttf").path(), index: 0, size: 9),
            largeRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSans-Bold.ttf").path(), index: 0, size: 15)
        )
        let otherFonts = [
            "ar": FontCollection(
                mainFont: Font(path: fontDirectoryPath.appending(component: "NotoSansArabic-Regular.ttf").path(), index: 0, size: 9),
                titleFont: Font(path: fontDirectoryPath.appending(component: "NotoSansArabic-Bold.ttf").path(), index: 0, size: 15),
                normalRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSansArabic-Regular.ttf").path(), index: 0, size: 9),
                largeRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSansArabic-Bold.ttf").path(), index: 0, size: 15)
            ),
            "ja": FontCollection(
                mainFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 0, size: 9),
                titleFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 0, size: 15),
                normalRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 0, size: 9),
                largeRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 0, size: 15)
            ),
            "ko": FontCollection(
                mainFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 1, size: 9),
                titleFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 1, size: 15),
                normalRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 1, size: 9),
                largeRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 1, size: 15)
            ),
            "zh_CN": FontCollection(
                mainFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 2, size: 9),
                titleFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 2, size: 15),
                normalRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 2, size: 9),
                largeRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 2, size: 15)
            ),
            "zh_TW": FontCollection(
                mainFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 3, size: 9),
                titleFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 3, size: 15),
                normalRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Regular.ttc").path(), index: 3, size: 9),
                largeRenderFont: Font(path: fontDirectoryPath.appending(component: "NotoSansCJK-Bold.ttc").path(), index: 3, size: 15)
            )
        ]

        return XRRenderer(renderer: Renderer(resourceFolderPath: resourceFolderPath, configFilePath: "celestia.cfg", userDefaultsPath:defaultConfigPlistPath, defaultFonts: defaultFonts, otherFonts: otherFonts))
    }()
    private let interactionManager = InteractionManager()

    var body: some Scene {
        WindowGroup {
            StartUpView()
                .environmentObject(renderer)
                .environmentObject(interactionManager)
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
