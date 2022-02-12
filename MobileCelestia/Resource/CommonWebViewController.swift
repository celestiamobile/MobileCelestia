//
// CommonWebViewController.swift
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

class CommonWebViewController: UIViewController {
    private let url: URL

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let handler = CelestiaScriptHandler()
        handler.delegate = self
        configuration.userContentController.add(handler, name: "iOSCelestia")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }()

    override func loadView() {
        view = webView
    }

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.load(URLRequest(url: url))
        webView.navigationDelegate = self
    }
}

extension CommonWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .other {
            decisionHandler(.allow)
            return
        }
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        // There should be no navigation inside the webview, for now
        // we only allow opening a webpage with the same host/path
        if url.host == self.url.host && url.path == self.url.path {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension CommonWebViewController: CelestiaScriptHandlerDelegate {
    func runScript(type: String, content: String) {
        guard ["cel", "celx"].contains(type) else { return }

        DispatchQueue.global().async {
            guard let data = content.data(using: .utf8) else { return }
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().hashValue).\(type)")
            do {
                try data.write(to: tempURL)
                AppCore.shared.run { core in
                    core.runScript(at: tempURL.path)
                }
            } catch {}
        }
    }

    func shareURL(title: String, url: URL) {
        DispatchQueue.main.async {
            self.showShareSheet(for: url)
        }
    }
}
