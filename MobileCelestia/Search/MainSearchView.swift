//
// MainSearchView.swift
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

#if targetEnvironment(macCatalyst)
@available(iOS 16.0, *)
struct MainSearchView: View {
    @State private var showingAlert = false

    var executor: CelestiaExecutor
    var core: AppCore

    @State var current: NameSelection? = nil

    var body: some View {
        NavigationSplitView {
            ObjectSearchView(executor: executor, selection: $current) { nameSelection in
                Text(nameSelection.name)
            } submitAction: { nameSelection in
                if nameSelection.selection.isEmpty {
                    showingAlert = true
                } else {
                    current = nameSelection
                }
            }
            .navigationSplitViewColumnWidth(min: 100, ideal: 200, max: 300)
        } detail: {
            if let current {
                InfoView(selection: current.selection, core: core, isEmbeddedInNavigationController: true)
                    .ignoresSafeArea(edges: .all)
                    .navigationTitle(core.simulation.universe.name(for: current.selection))
            } else {
                EmptyView()
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(CelestiaString("Object not found", comment: "")))
        }
    }
}
#else
@available(iOS 16.0, *)
struct MainSearchView: View {
    @State private var navigationPath = NavigationPath()
    @State private var showingAlert = false

    var executor: CelestiaExecutor
    var core: AppCore

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ObjectSearchView(executor: executor) { nameSelection in
                NavigationLink(value: nameSelection.selection) {
                    Text(nameSelection.name)
                }
            } submitAction: { nameSelection in
                if nameSelection.selection.isEmpty {
                    showingAlert = true
                } else {
                    navigationPath.append(nameSelection.selection)
                }
            }
            .navigationTitle(CelestiaString("Search", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Selection.self) { selection in
                InfoView(selection: selection, core: core, isEmbeddedInNavigationController: true)
                    .ignoresSafeArea(edges: .all)
                    .navigationTitle(core.simulation.universe.name(for: selection))
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(CelestiaString("Object not found", comment: "")))
        }
    }
}
#endif
