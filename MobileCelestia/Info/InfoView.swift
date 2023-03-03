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
import SwiftUI

struct InfoView: UIViewControllerRepresentable {
    let selection: Selection
    let core: AppCore
    let isEmbeddedInNavigationController: Bool

    func makeUIViewController(context: Context) -> some UIViewController {
        return InfoViewController(info: selection, core: core, isEmbeddedInNavigationController: isEmbeddedInNavigationController)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let viewController = uiViewController as? InfoViewController else { return }
        viewController.reload(info: selection)
    }
}

