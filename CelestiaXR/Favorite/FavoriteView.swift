//
// FavoriteView.swift
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

struct FavoriteView: UIViewControllerRepresentable {
    typealias UIViewControllerType = FavoriteCoordinatorController

    @EnvironmentObject var renderer: XRRenderer

    func makeUIViewController(context: Context) -> FavoriteCoordinatorController {
        return FavoriteCoordinatorController(executor: renderer, root: .main) {
            return nil
        } selected: { object in
            if let url = object as? URL {
                self.renderer.enqueue { core in
                    if url.isFileURL {
                        core.runScript(at: url.path())
                    } else {
                        core.go(to: url.absoluteString)
                    }
                }
            } else if let destination = object as? Destination {
                self.renderer.enqueue { $0.simulation.goToDestination(destination) }
            }
        } share: { _, viewController in
            // TODO: sharing
        } textInputHandler: { viewController, title, text in
            return await viewController.getTextInput(title, text: text)
        }
    }

    func updateUIViewController(_ uiViewController: FavoriteCoordinatorController, context: Context) {
    }
}
