// TimeSettingsView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import SwiftUI

struct TimeSettingsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController

    @Environment(XRRenderer.self) private var renderer

    func makeUIViewController(context: Context) -> UINavigationController {
        return UINavigationController(rootViewController: TimeSettingViewController(core: renderer.appCore, executor: renderer, dateInputHandler: { viewController, title, format in
            return await viewController.getDateInput(title, format: format)
        }, textInputHandler: { viewController, title, keyboardType in
            return await viewController.getTextInput(title, keyboardType: keyboardType)
        }))
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
