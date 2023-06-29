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

    @Environment(XRRenderer.self) private var renderer
    let resourceManager: ResourceManager
    let requestHandler: RequestHandler
    let category: CategoryInfo?

    func makeUIViewController(context: Context) -> UINavigationController {
        let baseURL: String
        if let category, category.isLeaf {
            baseURL = "https://celestia.mobi/resources/category"
        } else {
            baseURL = "https://celestia.mobi/resources/categories"
        }
        var components = URLComponents(string: baseURL)!
        var queryItems = [
            URLQueryItem(name: "lang", value: AppCore.language),
            URLQueryItem(name: "theme", value: "dark"),
            URLQueryItem(name: "platform", value: "ios"),
            URLQueryItem(name: "api", value: "1"),
        ]
        if let category {
            if category.isLeaf {
                queryItems.append(URLQueryItem(name: "category", value: category.category))
            } else {
                queryItems.append(URLQueryItem(name: "parent", value: category.category))
            }
        }
        components.queryItems = queryItems
        let url = components.url!
        return UINavigationController(rootViewController: CommonWebViewController(executor: renderer, resourceManager: resourceManager, url: url, requestHandler: requestHandler, actionHandler: { _, _ in }, filterURL: false))
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
