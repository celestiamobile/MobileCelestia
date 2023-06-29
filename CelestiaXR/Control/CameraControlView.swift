//
// CameraControlView.swift
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
import UIKit

struct CameraControlView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController

    @Environment(XRRenderer.self) private var renderer

    func makeUIViewController(context: Context) -> UINavigationController {
        return UINavigationController(rootViewController: CameraControlViewController(executor: renderer))
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
