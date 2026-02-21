// ResourceCategoriesViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

public class ResourceCategoriesViewController: ToolbarNavigationContainerController {
    private let webViewController: CommonWebViewController
    private let subscriptionManager: SubscriptionManager?
    private let category: CategoryInfo?

    public init(category: CategoryInfo?, executor: AsyncProviderExecutor, resourceManager: ResourceManager, subscriptionManager: SubscriptionManager?, requestHandler: RequestHandler, actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?) {
        self.category = category
        self.webViewController = CommonWebViewController(executor: executor, resourceManager: resourceManager, url: .categoryURL(category: category,subscriptionManager: subscriptionManager), requestHandler: requestHandler, actionHandler: actionHandler, filterURL: false)
        self.subscriptionManager = subscriptionManager
        super.init(rootViewController: webViewController)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(handleSubscriptionStatusChanged), name: .subscriptionStatusChanged, object: nil)
    }

    @objc private func handleSubscriptionStatusChanged() {
        guard let subscriptionManager else { return }

        switch subscriptionManager.status {
        case .verified:
            // We only handle not subscribed -> subscribed here
            break
        default:
            return
        }

        webViewController.reload(.categoryURL(category: category, subscriptionManager: subscriptionManager))
    }
}

private extension URL {
    @MainActor
    static func categoryURL(category: CategoryInfo?, subscriptionManager: SubscriptionManager?) -> URL {
        var queryItems = [URLQueryItem]()
        if let subscriptionManager {
            if let (transactionID, isSandbox) = subscriptionManager.transactionInfo() {
                queryItems.append(URLQueryItem(name: "transactionIdApple", value: "\(transactionID)"))
                queryItems.append(URLQueryItem(name: "isSandboxApple", value: isSandbox ? "1" : "0"))
            } else {
                queryItems.append(URLQueryItem(name: "transactionIdApple", value: ""))
                queryItems.append(URLQueryItem(name: "isSandboxApple", value: "1"))
            }
        }
        let baseURL: String
        if let category, category.isLeaf {
            baseURL = "https://celestia.mobi/resources/category"
        } else {
            baseURL = "https://celestia.mobi/resources/categories"
        }
        #if os(visionOS)
        let platform = "visionos"
        #else
        #if targetEnvironment(macCatalyst)
        let platform = "catalyst"
        #else
        let platform = "ios"
        #endif
        #endif
        var components = URLComponents(string: baseURL)!
        queryItems.append(contentsOf: [
            URLQueryItem(name: "lang", value: AppCore.language),
            URLQueryItem(name: "platform", value: platform),
            URLQueryItem(name: "api", value: "2"),
            URLQueryItem(name: "transparentBackground", value: "true"),
        ])
        if let category {
            if category.isLeaf {
                queryItems.append(URLQueryItem(name: "category", value: category.category))
            } else {
                queryItems.append(URLQueryItem(name: "parent", value: category.category))
            }
        }
        components.queryItems = queryItems
        return components.url!
    }
}
