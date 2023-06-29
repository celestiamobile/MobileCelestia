//
// HelpView.swift
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

struct HelpView: UIViewControllerRepresentable {
    typealias UIViewControllerType = HelpViewController

    @Environment(XRRenderer.self) private var renderer
    let resourceManager: ResourceManager
    let requestHandler: RequestHandler
    let assetProvider: AssetProvider

    func makeUIViewController(context: Context) -> HelpViewController {
        return HelpViewController(executor: renderer, resourceManager: resourceManager, requestHandler: requestHandler, assetProvider: assetProvider) { _, _ in }
    }

    func updateUIViewController(_ uiViewController: HelpViewController, context: Context) {
    }
}
