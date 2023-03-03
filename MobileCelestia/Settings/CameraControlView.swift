//
// CameraControlView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import SwiftUI

private class StepperCellState: ObservableObject {
    var currentKey: Int?
}

private struct StepperCell: View {
    let name: String
    let minusKey: Int
    let plusKey: Int
    let executor: CelestiaExecutor

    @StateObject private var state = StepperCellState()

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Stepper(label: {
                EmptyView()
            }) {
                let currentKey = state.currentKey
                if currentKey == plusKey { return }
                state.currentKey = plusKey
                executor.run { core in
                    if let currentKey {
                        core.keyUp(currentKey)
                    }
                    core.keyDown(plusKey)
                }
            } onDecrement: {
                let currentKey = state.currentKey
                if currentKey == minusKey { return }
                state.currentKey = minusKey
                executor.run { core in
                    if let currentKey {
                        core.keyUp(currentKey)
                    }
                    core.keyDown(minusKey)
                }
            } onEditingChanged: { editing in
                if !editing, let currentKey = state.currentKey {
                    state.currentKey = nil
                    executor.run { core in
                        core.keyUp(currentKey)
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
private struct CameraControlView: View {
    let executor: CelestiaExecutor

    var body: some View {
        Form {
            Section {
                StepperCell(name: CelestiaString("Pitch", comment: ""), minusKey: 32, plusKey: 26, executor: executor)
                StepperCell(name: CelestiaString("Yaw", comment: ""), minusKey: 28, plusKey: 30, executor: executor)
                StepperCell(name: CelestiaString("Roll", comment: ""), minusKey: 31, plusKey: 33, executor: executor)
            } footer: {
                Text(CelestiaString("Long press on stepper to change orientation.", comment: ""))
            }

            Section {
                Button {
                    Task {
                        await executor.run { $0.simulation.reverseObserverOrientation() }
                    }
                } label: {
                    Text(CelestiaString("Reverse Direction", comment: ""))
                }
            }
        }
        .navigationTitle(CelestiaString("Camera Control", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 16.0, *)
struct CameraControlNavigationView: View {
    let executor: CelestiaExecutor

    var body: some View {
        NavigationStack {
            CameraControlView(executor: executor)
        }
    }
}
