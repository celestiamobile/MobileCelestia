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
    private let matchingQueryKeys: [String]

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

    private lazy var activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13, *) {
            return UIActivityIndicatorView(style: .large)
        } else {
            return UIActivityIndicatorView(style: .whiteLarge)
        }
    }()

    override func loadView() {
        let containerView = UIView()
        containerView.addSubview(webView)
        containerView.addSubview(activityIndicator)
        webView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
        view = containerView
    }

    init(url: URL, matchingQueryKeys: [String]) {
        self.url = url
        self.matchingQueryKeys = matchingQueryKeys
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.startAnimating()
        webView.load(URLRequest(url: url))
        webView.navigationDelegate = self
    }
}

extension CommonWebViewController: WKNavigationDelegate {
    private func isURLAllowed(_ url: URL) -> Bool {
        let comp1 = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let comp2 = URLComponents(url: self.url, resolvingAgainstBaseURL: false)!
        if comp1.host != comp2.host || comp1.path != comp2.path {
            return false
        }
        for key in matchingQueryKeys {
            if comp1.queryItems?.first(where: { $0.name == key })?.value != comp2.queryItems?.first(where: { $0.name == key })?.value {
                return false
            }
        }
        return true
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .other {
            decisionHandler(.allow)
            return
        }
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        if isURLAllowed(url) {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
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
