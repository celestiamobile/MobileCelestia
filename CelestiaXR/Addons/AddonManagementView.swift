// AddonManagementView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import SwiftUI

struct AddonManagementView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ResourceViewController

    @Environment(WindowManager.self) private var windowManager
    @Environment(XRRenderer.self) private var renderer
    let resourceManager: ResourceManager
    let requestHandler: RequestHandler

    func makeUIViewController(context: Context) -> ResourceViewController {
        return ResourceViewController(
            executor: renderer,
            resourceManager: resourceManager,
            requestHandler: requestHandler,
            actionHandler: { action, _ in
            },
            getAddonHandler: {
                windowManager.tool = .downloadAddons
            }
        )
    }

    func updateUIViewController(_ uiViewController: ResourceViewController, context: Context) {
    }
}
