//
// RelatedAddonsViewController.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

public class RelatedAddonsViewController: ToolbarNavigationContainerController {
    private let webViewController: CommonWebViewController
    private let subscriptionManager: SubscriptionManager
    private let objectPath: String

    public init(objectPath: String, executor: AsyncProviderExecutor, resourceManager: ResourceManager, subscriptionManager: SubscriptionManager, requestHandler: RequestHandler, actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?) {
        self.objectPath = objectPath
        self.webViewController = CommonWebViewController(executor: executor, resourceManager: resourceManager, url: .relatedAddonsURL(objectPath: objectPath,subscriptionManager: subscriptionManager), requestHandler: requestHandler, actionHandler: actionHandler, filterURL: false)
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

        webViewController.reload(.relatedAddonsURL(objectPath: objectPath, subscriptionManager: subscriptionManager))
    }
}

private extension URL {
    @MainActor
    static func relatedAddonsURL(objectPath: String, subscriptionManager: SubscriptionManager) -> URL {
        var queryItems = [URLQueryItem]()
        if let (transactionID, isSandbox) = subscriptionManager.transactionInfo() {
            queryItems.append(URLQueryItem(name: "transactionIdApple", value: "\(transactionID)"))
            queryItems.append(URLQueryItem(name: "isSandboxApple", value: isSandbox ? "1" : "0"))
        } else {
            queryItems.append(URLQueryItem(name: "transactionIdApple", value: ""))
            queryItems.append(URLQueryItem(name: "isSandboxApple", value: "1"))
        }
        let baseURL = "https://celestia.mobi/resources/itemsByObjectPath"
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
            URLQueryItem(name: "objectPath", value: objectPath),
            URLQueryItem(name: "lang", value: AppCore.language),
            URLQueryItem(name: "platform", value: platform),
            URLQueryItem(name: "transparentBackground", value: "true"),
            URLQueryItem(name: "api", value: "2"),
        ])
        components.queryItems = queryItems
        return components.url!
    }
}
