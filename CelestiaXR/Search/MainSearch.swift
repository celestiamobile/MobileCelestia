//
// MainSearch.swift
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

struct MainSearch: UIViewControllerRepresentable {
    typealias UIViewControllerType = SearchCoordinatorController

    @Environment(XRRenderer.self) private var renderer
    @Environment(BrowserItemStore.self) private var browerItemStore
    @Environment(\.openWindow) private var openWindow

    func makeUIViewController(context: Context) -> SearchCoordinatorController {
        return SearchCoordinatorController(executor: renderer) { selection in
            let vc = InfoViewController(info: selection, core: renderer.appCore, executor: renderer, showNavigationTitle: false, backgroundColor: nil)
            vc.selectionHandler = { selection, action in
                switch action {
                case .subsystem:
                   openSubsystemBrowser(selection)
                }
            }
            return vc
        }
    }

    func updateUIViewController(_ uiViewController: SearchCoordinatorController, context: Context) {
    }

    private func openSubsystemBrowser(_ selection: Selection) {
        if let entry = selection.object {
            let item = BrowserItem(name: renderer.appCore.simulation.universe.name(for: selection), catEntry: entry, provider: renderer.appCore.simulation.universe)
            if let id = browerItemStore.save(item: item) {
                openWindow(id: "SubsystemWindow", value: id)
            }
        }
    }
}
