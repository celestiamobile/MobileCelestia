//
// AddonCategoryView.swift
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

struct AddonCategoriesView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController

    @EnvironmentObject private var renderer: XRRenderer
    @EnvironmentObject private var resourceManager: ResourceManager

    func makeUIViewController(context: Context) -> UINavigationController {
        let baseURL = "https://celestia.mobi/resources/categories"
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "lang", value: AppCore.language),
            URLQueryItem(name: "theme", value: "dark"),
            URLQueryItem(name: "platform", value: "ios"),
            URLQueryItem(name: "api", value: "1"),
        ]
        let url = components.url!
        return UINavigationController(rootViewController: CommonWebViewController(executor: renderer, resourceManager: resourceManager, url: url, filterURL: false))
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
