// StartUpView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaUI
import SwiftUI

struct StartUpView: View {
    @Environment(WindowManager.self) private var windowManager
    @Environment(XRRenderer.self) private var renderer
    @Environment(InteractionManager.self) private var interactionManager

    private enum ImmersiveSpaceState {
        case notOpened
        case dismissing
        case opening
        case opened
    }

    @Binding var immersionStyle: any ImmersionStyle

    @State private var immersiveSpaceState: ImmersiveSpaceState = .notOpened

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    private let bottomActions: [CelestiaAction] = [.slower, .playpause, .faster, .reverse]

    var body: some View {
        Group {
            switch renderer.rendererStatus {
            case .loading, .loaded, .invalidated, .failed:
                OnboardingView(isOpeningImmersiveSpace: immersiveSpaceState == .opening, immersionStyle: $immersionStyle, startAction: {
                    Task {
                        immersiveSpaceState = .opening
                        await openImmersiveSpace(id: "ImmersiveSpace")
                        immersiveSpaceState = .opened
                        if !windowManager.isInfoWindowVisible {
                            openWindow(id: "InfoWindow")
                        }
                    }
                })
                .padding()
            case .rendering:
                NavigationStack {
                    RunningView { action in
                        switch action {
                        case .pause:
                            Task {
                                immersiveSpaceState = .dismissing
                                await dismissImmersiveSpace()
                                immersiveSpaceState = .notOpened
                            }
                        case .openInfo:
                            if !windowManager.isInfoWindowVisible {
                                openWindow(id: "InfoWindow")
                            }
                        case .openTool(let tool):
                            windowManager.tool = tool
                            if !windowManager.isToolWindowVisible {
                                openWindow(id: "Tool")
                            }
                        }
                    }
                    .padding()
                }
                .ornament(attachmentAnchor: .scene(.bottom)) {
                    BottomActionView()
                }
            case .none:
                Text("Unknown status")
                    .padding()
            @unknown default:
                Text("Unknown status")
                    .padding()
            }
        }
    }
}
