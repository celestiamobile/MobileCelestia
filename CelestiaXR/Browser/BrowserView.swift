//
// BrowserView.swift
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

struct BrowserView: UIViewControllerRepresentable {
    typealias UIViewControllerType = BrowserContainerViewController

    @EnvironmentObject private var renderer: XRRenderer

    func makeUIViewController(context: Context) -> BrowserContainerViewController {
        let vc = BrowserContainerViewController(selected: { selection in
            return UIHostingController(rootView: InfoView(selection: selection, isEmbeddedInNavigationController: true))
        }, executor: renderer)
        return vc
    }

    func updateUIViewController(_ uiViewController: BrowserContainerViewController, context: Context) {
    }
}
