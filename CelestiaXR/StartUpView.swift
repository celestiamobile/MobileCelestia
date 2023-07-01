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

    @State var isDismissingImmersiveSpace = false
    @State var isOpeningImmersiveSpace = false
    @State var isImmersiveSpaceOpened = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow

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
        VStack {
            Text("Celestia is running...")
            Button("Open Browser") {
                openWindow(id: "BrowserWindow")
            }
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
                if let currentFileName = renderer.currentFileName {
                    Text("Celestia is loading \(currentFileName)")
                } else {
                    Text("Celestia is loading...")
                }
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
    }
}
