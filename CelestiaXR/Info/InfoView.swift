// InfoView.swift
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

struct InfoView: UIViewControllerRepresentable {
    typealias UIViewControllerType = InfoViewController

    @Environment(XRRenderer.self) private var renderer
    @Environment(\.openWindow) private var openWindow
    @Environment(BrowserItemStore.self) private var browerItemStore

    let selection: Selection
    let isEmbeddedInNavigationController: Bool

    private func openSubsystemBrowser(_ selection: Selection) {
        if let entry = selection.object {
            let item = BrowserItem(name: renderer.appCore.simulation.universe.name(for: selection), catEntry: entry, provider: renderer.appCore.simulation.universe)
            if let id = browerItemStore.save(item: item) {
                openWindow(id: "SubsystemWindow", value: id)
            }
        }
    }

    func makeUIViewController(context: Context) -> InfoViewController {
        let vc = InfoViewController(info: selection, core: renderer.appCore, executor: renderer, showNavigationTitle: isEmbeddedInNavigationController, backgroundColor: nil)
        vc.selectionHandler = { selection, action in
            switch action {
            case .subsystem:
               openSubsystemBrowser(selection)
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: InfoViewController, context: Context) {
        uiViewController.setSelection(selection)
    }
}
