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
    private let contextDirectory: URL?
    private let filterURL: Bool

    var ackHandler: ((String) -> Void)?

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

    private lazy var toolbar = UIToolbar()
    private lazy var goBackItem: UIBarButtonItem = {
        let isRTL = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft
        return UIBarButtonItem(image: UIImage(systemName: isRTL ? "chevron.right" : "chevron.left"), style: .plain, target: self, action: #selector(goBack))
    }()
    private lazy var goForwardItem: UIBarButtonItem = {
        let isRTL = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft
        return UIBarButtonItem(image: UIImage(systemName: isRTL ? "chevron.left" : "chevron.right"), style: .plain, target: self, action: #selector(goForward))
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
        containerView.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            toolbar.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
        view = containerView
    }

    init(url: URL, matchingQueryKeys: [String], contextDirectory: URL? = nil) {
        self.url = url
        self.matchingQueryKeys = matchingQueryKeys
        self.contextDirectory = contextDirectory
        self.filterURL = true
        super.init(nibName: nil, bundle: nil)
    }

    init(url: URL) {
        self.url = url
        self.matchingQueryKeys = []
        self.contextDirectory = nil
        self.filterURL = false
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            goBackItem,
            goForwardItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
        ]
        toolbar.isHidden = true
        activityIndicator.startAnimating()
        webView.load(URLRequest(url: url))
        webView.navigationDelegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let toolbarHeight = toolbar.isHidden ? 0 : toolbar.frame.height
        if webView.scrollView.contentInset.bottom != toolbarHeight {
            webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: toolbarHeight, right: 0)
        }
    }

    private func updateNavigation() {
        toolbar.isHidden = !webView.canGoBack && !webView.canGoForward
        goBackItem.isEnabled = webView.canGoBack
        goForwardItem.isEnabled = webView.canGoForward
        let toolbarHeight = toolbar.isHidden ? 0 : toolbar.frame.height
        webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: toolbarHeight, right: 0)
    }

    @objc private func goBack() {
        webView.goBack()
    }

    @objc private func goForward() {
        webView.goForward()
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
        if !filterURL {
            decisionHandler(.allow)
            return
        }
        if navigationAction.targetFrame?.isMainFrame == false {
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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationItem.title = webView.title
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        updateNavigation()
    }
}

extension CommonWebViewController: CelestiaScriptHandlerDelegate {
    func runScript(type: String, content: String, name: String?, location: String?) {
        guard ["cel", "celx"].contains(type) else { return }

        let scriptURL: URL
        let scriptFileName = (name ?? UUID().uuidString) + "." + type
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(scriptFileName)
        if let location = location {
            guard ["temp", "context"].contains(location) else { return }
            if location == "context" {
                guard let parent = contextDirectory else {
                    return
                }
                scriptURL = parent.appendingPathComponent(scriptFileName)
            } else {
                scriptURL = tempURL
            }
        } else {
            scriptURL = tempURL
        }

        DispatchQueue.global().async {
            guard let data = content.data(using: .utf8) else { return }
            do {
                try data.write(to: scriptURL)
                AppCore.shared.run { core in
                    core.runScript(at: scriptURL.path)
                }
            } catch {}
        }
    }

    func shareURL(title: String, url: URL) {
        DispatchQueue.main.async {
            self.showShareSheet(for: url)
        }
    }

    func receivedACK(id: String) {
        ackHandler?(id)
    }

    func openAddonNext(id: String) {
        let requestURL = apiPrefix + "/resource/item"
        _ = RequestHandler.get(url: requestURL, parameters: ["lang": AppCore.language, "item": id], success: { [weak self] (item: ResourceItem) in
            guard let self = self else { return }
            self.navigationController?.pushViewController(ResourceItemViewController(item: item), animated: true)
        }, decoder: ResourceItem.networkResponseDecoder)
    }
}
