//
// FallbackWebViewController.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public class FallbackWebViewController: UIViewController {
    private let webViewController: CommonWebViewController
    private let fallbackViewControllerCreator: () -> UIViewController

    public init(executor: AsyncProviderExecutor, resourceManager: ResourceManager, url: URL, actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?, matchingQueryKeys: [String] = [], contextDirectory: URL? = nil, filterURL: Bool = true, fallbackViewControllerCreator: @escaping @autoclosure () -> UIViewController) {
        webViewController = CommonWebViewController(executor: executor, resourceManager: resourceManager, url: url, actionHandler: actionHandler, matchingQueryKeys: matchingQueryKeys, contextDirectory: contextDirectory, filterURL: filterURL)
        self.fallbackViewControllerCreator = fallbackViewControllerCreator
        super.init(nibName: nil, bundle: nil)
    }

    public override func loadView() {
        let container = UIView()
        container.backgroundColor = .systemBackground
        view = container
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        webViewController.delegate = self
        install(webViewController)
    }
}

extension FallbackWebViewController: CommonWebViewControllerDelegate {
    func webViewLoadFailed() {
        guard webViewController.parent == self else { return }
        webViewController.remove()

        install(fallbackViewControllerCreator())
    }
}
