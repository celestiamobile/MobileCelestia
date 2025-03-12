// GoToView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import SwiftUI

struct GoToView: UIViewControllerRepresentable {
    typealias UIViewControllerType = GoToContainerViewController

    @Environment(XRRenderer.self) private var renderer

    func makeUIViewController(context: Context) -> GoToContainerViewController {
        return GoToContainerViewController(executor: renderer) { location in
            renderer.enqueue { core in
                core.simulation.go(to: location)
            }
        } textInputHandler: { viewController, title, text, keyboardType in
            return await viewController.getTextInput(title, text: text, keyboardType: keyboardType)
        }
    }

    func updateUIViewController(_ uiViewController: GoToContainerViewController, context: Context) {
    }
}
