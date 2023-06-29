//
// GuideView.swift
//
// Copyright © 2024 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import CelestiaUI
import SwiftUI

struct GuideView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CommonWebViewController

    @Environment(XRRenderer.self) private var renderer

    let id: String
    let resourceManager: ResourceManager
    let requestHandler: RequestHandler

    func makeUIViewController(context: Context) -> CommonWebViewController {
        return CommonWebViewController(executor: renderer, resourceManager: resourceManager, url: .fromGuide(guideItemID: id, language: AppCore.language), requestHandler: requestHandler, actionHandler: { action, viewController in
        }, matchingQueryKeys: ["guide"])
    }

    func updateUIViewController(_ uiViewController: CommonWebViewController, context: Context) {
    }
}
