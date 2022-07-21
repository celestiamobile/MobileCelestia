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

class FallbackWebViewController: UIViewController {
    private let webViewController: CommonWebViewController
    private let fallbackViewControllerCreator: () -> UIViewController

    init(url: URL, matchingQueryKeys: [String] = [], contextDirectory: URL? = nil, filterURL: Bool = true, fallbackViewControllerCreator: @escaping @autoclosure () -> UIViewController) {
        webViewController = CommonWebViewController(url: url, matchingQueryKeys: matchingQueryKeys, contextDirectory: contextDirectory, filterURL: filterURL)
        self.fallbackViewControllerCreator = fallbackViewControllerCreator
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        let container = UIView()
        container.backgroundColor = .systemBackground
        view = container
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
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
