// EclipseFinder.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import SwiftUI

struct EclipseFinder: UIViewControllerRepresentable {
    typealias UIViewControllerType = EventFinderCoordinatorViewController

    @Environment(XRRenderer.self) private var renderer

    func makeUIViewController(context: Context) -> EventFinderCoordinatorViewController {
        return EventFinderCoordinatorViewController(executor: renderer) { eclipse in
            renderer.enqueue { core in
                core.simulation.goToEclipse(eclipse)
            }
        } textInputHandler: { viewController, title in
            return await viewController.getTextInput(title)
        } dateInputHandler: { viewController, title, format in
            return await viewController.getDateInput(title, format: format)
        }
    }

    func updateUIViewController(_ uiViewController: EventFinderCoordinatorViewController, context: Context) {
    }
}
