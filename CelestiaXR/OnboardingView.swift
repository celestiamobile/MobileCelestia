//
// OnboardingView.swift
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

struct OnboardingView: View {
    @Environment(InteractionManager.self) private var interactionManager
    @Environment(XRRenderer.self) private var renderer

    let isOpeningImmersiveSpace: Bool
    @Binding var immersionStyle: any ImmersionStyle
    let startAction: () -> Void

    @State private var useMixedImmersion: Bool

    init(isOpeningImmersiveSpace: Bool, immersionStyle: Binding<any ImmersionStyle>, startAction: @escaping () -> Void) {
        self.isOpeningImmersiveSpace = isOpeningImmersiveSpace
        self._immersionStyle = immersionStyle
        self.startAction = startAction
        self.useMixedImmersion = immersionStyle.wrappedValue is MixedImmersionStyle
    }

    var body: some View {
        VStack(alignment: .center, spacing: LayoutConstants.largeVerticalSpacing) {
            Text("Welcome to Celestia")
                .font(.extraLargeTitle2)

            if renderer.rendererStatus == .loading {
                Text("Please wait while we load essential files for Celestia")
                    .font(.title)
            }

            Grid {
                GridRow {
                    Image(systemName: "gamecontroller.fill")
                        .frame(minWidth: 0, maxWidth: .infinity)
                    if renderer.rendererStatus == .loading {
                        Image(systemName: "slowmo")
                            .symbolEffect(.variableColor.cumulative)
                            .frame(minWidth: 0, maxWidth: .infinity)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .frame(minWidth: 0, maxWidth: .infinity)
                    }
                }
                .font(.extraLargeTitle)

                GridRow {
                    Text("Game Controller")
                        .frame(minWidth: 0, maxWidth: .infinity)
                    Text("Celestia Data")
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                .font(.largeTitle)

                GridRow {
                    Text(interactionManager.connectedGameController == nil ? "Not Connected" : "Connected")
                        .frame(minWidth: 0, maxWidth: .infinity)
                    if renderer.rendererStatus == .loading {
                        if let filename = renderer.currentFileName {
                            Text(filename)
                                .frame(minWidth: 0, maxWidth: .infinity)
                        } else {
                            Text("Loading")
                                .frame(minWidth: 0, maxWidth: .infinity)
                        }
                    } else {
                        Text("Loaded")
                            .frame(minWidth: 0, maxWidth: .infinity)
                    }
                }
                .font(.title)
            }

            if renderer.rendererStatus == .failed {
                Text("Loading Celestia failed…")
                    .font(.body)
            } else if renderer.rendererStatus != .loading {
                VStack(spacing: 16) {
                    if #available(visionOS 2, *) {
                        Toggle(isOn: $useMixedImmersion) {
                            Text("Use Mixed Immersion")
                        }
                        .fixedSize()
                    }
                    Button(action: startAction) {
                        Text("Start Celestia")
                    }
                }
                .disabled(isOpeningImmersiveSpace)
            }
        }
        .onChange(of: useMixedImmersion) { _, _ in
            immersionStyle = useMixedImmersion ? .mixed : .full
            renderer.updateImmersionStyle(useMixedImmersion: useMixedImmersion)
        }
    }
}
