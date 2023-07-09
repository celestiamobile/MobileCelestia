//
// ContentView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import CelestiaUI
import SwiftUI

struct StartUpView: View {
    @EnvironmentObject var renderer: XRRenderer
    @EnvironmentObject var interactionManager: InteractionManager

    @State var isDismissingImmersiveSpace = false
    @State var isOpeningImmersiveSpace = false
    @State var isImmersiveSpaceOpened = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow

    private let toolboxItems: [ToolboxView.Item] = [
        ToolboxView.Item(image: "globe", title: "Browser", windowGroupID: "BrowserWindow"),
        ToolboxView.Item(image: "magnifyingglass", title: "Search", windowGroupID: "MainSearch"),
        ToolboxView.Item(image: "paperplane", title: "Go to Object", windowGroupID: "GoTo"),
        ToolboxView.Item(image: "calendar", title: "Eclipse Finder", windowGroupID: "EclipseFinder"),
        ToolboxView.Item(image: "video", title: "Camera Control", windowGroupID: "CameraControl"),
        ToolboxView.Item(image: "star.circle", title: "Favorites", windowGroupID: "FavoriteView"),
        ToolboxView.Item(image: "gear", title: "Settings", windowGroupID: "SettingsView"),
        ToolboxView.Item(image: "folder", title: "Installed Add-ons", windowGroupID: "AddonManagementView"),
        ToolboxView.Item(image: "square.and.arrow.down", title: "Get Add-ons", windowGroupID: "AddonCategoriesView"),
        ToolboxView.Item(image: "questionmark.circle", title: "Help", windowGroupID: "HelpView"),
    ]

    @ViewBuilder
    func startCelestiaView() -> some View {
        Button("Start Celestia") {
            Task {
                isOpeningImmersiveSpace = true
                await openImmersiveSpace(id: "ImmersiveSpace")
                isOpeningImmersiveSpace = false
                isImmersiveSpaceOpened = true
                openWindow(id: "InfoWindow")
            }
        }
    }

    @ViewBuilder
    func celestiaRunningView() -> some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 24) {
                    HStack {
                        Text("Tools")
                            .font(.extraLargeTitle2)
                        Spacer()
                    }
                    ToolboxView(items: toolboxItems)
                    Button("Pause Celestia") {
                        Task {
                            isDismissingImmersiveSpace = true
                            await dismissImmersiveSpace()
                            isDismissingImmersiveSpace = false
                            isImmersiveSpaceOpened = false
                            dismissWindow(id: "InfoWindow")
                        }
                    }
                }
                if !renderer
                    .message.isEmpty {
                    VStack(spacing: 24) {
                        HStack {
                            Text("Messages")
                                .font(.extraLargeTitle2)
                            Spacer()
                        }
                        HStack {
                            Text(renderer.message)
                                .font(.largeTitle)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    var body: some View {
        VStack {
            switch renderer.rendererStatus {
            case .none:
                Button("Load Celestia") {
                    renderer.prepare()
                }
            case .invalidated:
                Button("Load Celestia") {
                    renderer.updateRenderer()
                    renderer.prepare()
                }
            case .loading:
                LoadingView(currentFile: renderer.currentFileName)
            case .loaded:
                if isOpeningImmersiveSpace {
                    Text("Celestia is starting...")
                } else {
                    startCelestiaView()
                }
            case .rendering:
                if isOpeningImmersiveSpace {
                    Text("Celestia is starting...")
                } else if isDismissingImmersiveSpace {
                    Text("Celestia is pausing...")
                } else if isImmersiveSpaceOpened {
                    celestiaRunningView()
                } else {
                    startCelestiaView()
                }
            @unknown default:
                Text("Unknown status")
            }
        }
        .padding()
        .onChange(of: renderer.rendererStatus) { _, newValue in
            if newValue == .rendering, interactionManager.gameControllerManager == nil {
                let renderer = self.renderer
                interactionManager.gameControllerManager = GameControllerManager(executor: renderer, canAcceptEvents: { return renderer.rendererStatus == .rendering })
            }
        }
    }
}
