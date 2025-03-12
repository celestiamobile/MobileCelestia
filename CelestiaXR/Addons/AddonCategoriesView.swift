// AddonCategoriesView.swift
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

struct AddonCategoriesView: UIViewControllerRepresentable {
    @Environment(XRRenderer.self) private var renderer
    let resourceManager: ResourceManager
    let requestHandler: RequestHandler
    let category: CategoryInfo?

    func makeUIViewController(context: Context) -> ResourceCategoriesViewController {
        return ResourceCategoriesViewController(category: category, executor: renderer, resourceManager: resourceManager, subscriptionManager: nil, requestHandler: requestHandler, actionHandler: { _, _ in })
    }

    func updateUIViewController(_ uiViewController: ResourceCategoriesViewController, context: Context) {}
}
