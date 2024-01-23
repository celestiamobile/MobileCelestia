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

public class ResourceCategoriesViewController: ToolbarNavigationContainerController {
    private let webViewController: CommonWebViewController
    private let subscriptionManager: SubscriptionManager

    public init(executor: AsyncProviderExecutor, resourceManager: ResourceManager, subscriptionManager: SubscriptionManager, actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?) {
        self.webViewController = CommonWebViewController(executor: executor, resourceManager: resourceManager, url: .categoryURL(subscriptionManager: subscriptionManager), actionHandler: actionHandler, filterURL: false)
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
        switch subscriptionManager.status {
        case .verified:
            // We only handle not subscribed -> subscribed here
            break
        default:
            return
        }

        webViewController.reload(.categoryURL(subscriptionManager: subscriptionManager))
    }
}

private extension URL {
    @MainActor
    static func categoryURL(subscriptionManager: SubscriptionManager) -> URL {
        var queryItems = [URLQueryItem]()
        if #available(iOS 15, *) {
            if let (transactionID, isSandbox) = subscriptionManager.transactionInfo() {
                queryItems.append(URLQueryItem(name: "transactionIdApple", value: "\(transactionID)"))
                queryItems.append(URLQueryItem(name: "isSandboxApple", value: isSandbox ? "1" : "0"))
            } else {
                queryItems.append(URLQueryItem(name: "transactionIdApple", value: ""))
                queryItems.append(URLQueryItem(name: "isSandboxApple", value: "1"))
            }
        }
        let baseURL = "https://celestia.mobi/resources/categories"
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
            URLQueryItem(name: "theme", value: "dark"),
            URLQueryItem(name: "platform", value: platform),
            URLQueryItem(name: "api", value: "1"),
        ])
        components.queryItems = queryItems
        return components.url!
    }
}
