//
// ResourceCategoriesViewController.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

public class ResourceCategoriesViewController: UINavigationController {
    public init(executor: AsyncProviderExecutor, resourceManager: ResourceManager) {
        let baseURL = "https://celestia.mobi/resources/categories"
        #if targetEnvironment(macCatalyst)
        let platform = "catalyst"
        #else
        let platform = "ios"
        #endif
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "lang", value: AppCore.language),
            URLQueryItem(name: "theme", value: "dark"),
            URLQueryItem(name: "platform", value: platform),
            URLQueryItem(name: "api", value: "1"),
        ]
        let url = components.url!
        super.init(rootViewController: CommonWebViewController(executor: executor, resourceManager: resourceManager, url: url, filterURL: false))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
