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
    typealias UIViewControllerType = ResourceItemViewController

    @EnvironmentObject private var renderer: XRRenderer
    @EnvironmentObject private var resourceManager: ResourceManager

    let item: ResourceItem

    func makeUIViewController(context: Context) -> ResourceItemViewController {
        return ResourceItemViewController(executor: renderer, resourceManager: resourceManager, item: item, needsRefetchItem: false)
    }

    func updateUIViewController(_ uiViewController: ResourceItemViewController, context: Context) {
    }
}
