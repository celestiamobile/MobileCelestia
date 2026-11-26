// FallbackWebViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

public class FallbackWebViewController: UIViewController {
    private let webViewController: CommonWebViewController
    private var currentViewController: UIViewController
    private let fallbackViewControllerCreator: () -> UIViewController

    public init(executor: AsyncProviderExecutor, resourceManager: ResourceManager, url: URL, requestHandler: RequestHandler, actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?, matchingQueryKeys: [String] = [], contextDirectory: URL? = nil, filterURL: Bool = true, showsGuideHeader: Bool = false, fallbackViewControllerCreator: @escaping @autoclosure () -> UIViewController) {
        webViewController = CommonWebViewController(executor: executor, resourceManager: resourceManager, url: url, requestHandler: requestHandler, actionHandler: actionHandler, matchingQueryKeys: matchingQueryKeys, contextDirectory: contextDirectory, filterURL: filterURL, showsGuideHeader: showsGuideHeader)
        self.currentViewController = webViewController
        self.fallbackViewControllerCreator = fallbackViewControllerCreator
        super.init(nibName: nil, bundle: nil)
    }

    public override func loadView() {
        let container = UIView()
        #if !os(visionOS)
        container.backgroundColor = .systemBackground
        #endif
        view = container
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        webViewController.delegate = self
        webViewController.title = title
        install(webViewController)
        observeWindowTitle(for: webViewController)
    }

    public override var minimumSheetHeight: CGFloat {
        return currentViewController.minimumSheetHeight
    }
}

extension FallbackWebViewController: CommonWebViewControllerDelegate {
    func webViewNavigationItemUpdated(_ navigationItem: UINavigationItem) {
        guard webViewController.parent == self else { return }
        self.navigationItem.title = navigationItem.title
        self.navigationItem.leftBarButtonItem = navigationItem.leftBarButtonItem
        self.navigationItem.rightBarButtonItem = navigationItem.rightBarButtonItem
        windowSubtitle = webViewController.windowSubtitle
        #if !os(visionOS)
        if #available(anyAppleOS 26.0, *) {
            self.navigationItem.subtitle = navigationItem.subtitle
        }
        #endif
    }

    func webViewLoadFailed() {
        guard webViewController.parent == self else { return }
        webViewController.remove()

        let viewController = fallbackViewControllerCreator()
        currentViewController = viewController
        install(viewController)
        observeWindowTitle(for: viewController)
        navigationItem.title = viewController.title
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
        windowSubtitle = nil
        #if !os(visionOS)
        if #available(anyAppleOS 26.0, *) {
            navigationItem.subtitle = nil
        }
        #endif
    }
}
