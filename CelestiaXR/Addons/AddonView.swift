//
// AddonView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import SwiftUI

struct AddonView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController

    @Environment(XRRenderer.self) private var renderer

    let resourceManager: ResourceManager
    let requestHandler: RequestHandler
    let item: ResourceItem

    func makeUIViewController(context: Context) -> UINavigationController {
        return UINavigationController(rootViewController: ResourceItemViewController(executor: renderer, resourceManager: resourceManager, item: item, needsRefetchItem: false, requestHandler: requestHandler) { _, _ in })
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
