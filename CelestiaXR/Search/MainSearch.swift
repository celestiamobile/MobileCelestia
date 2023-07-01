//
// MainSearch.swift
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

struct MainSearch: UIViewControllerRepresentable {
    typealias UIViewControllerType = SearchCoordinatorController

    @EnvironmentObject private var renderer: XRRenderer

    func makeUIViewController(context: Context) -> SearchCoordinatorController {
        return SearchCoordinatorController(executor: renderer) { selection, isEmbeddedInNavigation in
            return UIHostingController(rootView: InfoView(selection: selection, isEmbeddedInNavigationController: isEmbeddedInNavigation))
        }
    }

    func updateUIViewController(_ uiViewController: SearchCoordinatorController, context: Context) {
    }
}
