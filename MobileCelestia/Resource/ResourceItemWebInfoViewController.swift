//
// ResourceItemWebInfoViewController.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit
import WebKit

class ResourceItemWebInfoViewController: UIViewController {
    private var item: ResourceItem

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }()

    override func loadView() {
        view = webView
    }

    init(item: ResourceItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let baseURL = "https://celestia.mobi/resources/item"
        let locale = LocalizedString("LANGUAGE", "celestia")
        guard var components = URLComponents(string: baseURL) else { return }
        components.queryItems = [
            URLQueryItem(name: "item", value: item.id),
            URLQueryItem(name: "lang", value: locale),
            URLQueryItem(name: "environment", value: "app"),
            URLQueryItem(name: "theme", value: "dark")
        ]
        guard let url = components.url else { return }

        webView.load(URLRequest(url: url))
        webView.navigationDelegate = self
    }
}

extension ResourceItemWebInfoViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .other {
            decisionHandler(.allow)
            return
        }
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        if url.host == "celestia.mobi" {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
