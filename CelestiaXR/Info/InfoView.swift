//
// InfoView.swift
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

struct InfoView: UIViewControllerRepresentable {
    typealias UIViewControllerType = InfoViewController

    @Environment(\.openWindow) private var openWindow

    @EnvironmentObject private var renderer: XRRenderer
    @EnvironmentObject private var browerItemStore: BrowserItemStore

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
        let vc = InfoViewController(info: selection, core: renderer.appCore, isEmbeddedInNavigationController: false)
        vc.selectionHandler = { _, selection, action, _ in
            switch action {
            case .select:
                renderer.enqueue { appCore in
                    appCore.simulation.selection = selection
                }
            case .web:
                // TODO: call open URL?
                break
            case let .wrapped(action):
                renderer.enqueue { appCore in
                    appCore.simulation.selection = selection
                    appCore.receive(action)
                }
            case .subsystem:
               openSubsystemBrowser(selection)
            case .alternateSurfaces:
                // TODO: present menu from the view
                break
            case .mark:
                // TODO: should probably just remove this action
                break
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: InfoViewController, context: Context) {
        uiViewController.setSelection(selection)
    }
}
