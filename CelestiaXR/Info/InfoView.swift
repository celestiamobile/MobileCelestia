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

    @EnvironmentObject var renderer: XRRenderer

    let selection: Selection
    let isEmbeddedInNavigationController: Bool

    func makeUIViewController(context: Context) -> InfoViewController {
        let vc = InfoViewController(info: selection, core: renderer.appCore, isEmbeddedInNavigationController: false)
        vc.selectionHandler = { _, action, _ in
            renderer.enqueue { appCore in
                switch action {
                case .select:
                    appCore.simulation.selection = selection
                case .web:
                    // TODO: call open URL?
                    break
                case let .wrapped(action):
                    appCore.simulation.selection = selection
                    appCore.receive(action)
                case .subsystem:
                    // TODO: show a window
                    break
                case .alternateSurfaces:
                    // TODO: present menu from the view
                    break
                case .mark:
                    // TODO: should probably just remove this action
                    break
                }
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: InfoViewController, context: Context) {
        uiViewController.setSelection(selection)
    }
}
