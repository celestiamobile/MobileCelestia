//
// SubsystemBrowserView.swift
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

struct SubsystemBrowserView: UIViewControllerRepresentable {
    typealias UIViewControllerType = SubsystemBrowserCoordinatorViewController

    @EnvironmentObject private var renderer: XRRenderer

    let item: BrowserItem

    func makeUIViewController(context: Context) -> SubsystemBrowserCoordinatorViewController {
        return SubsystemBrowserCoordinatorViewController(item: item) { selection in
            return UIHostingController(rootView: InfoView(selection: selection, isEmbeddedInNavigationController: true))
        }
    }

    func updateUIViewController(_ uiViewController: SubsystemBrowserCoordinatorViewController, context: Context) {
    }
}
