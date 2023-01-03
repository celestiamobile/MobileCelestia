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

protocol CommonWebViewControllerDelegate: AnyObject {
    func webViewLoadFailed()
}

class CommonWebViewController: UIViewController {
    private let url: URL
    private let matchingQueryKeys: [String]
    private let contextDirectory: URL?
    private let filterURL: Bool
    private var titleObservation: NSKeyValueObservation?

    weak var delegate: CommonWebViewControllerDelegate?

    var ackHandler: ((String) -> Void)?

    private let webView: WKWebView

    private lazy var goBackItem: UIBarButtonItem = {
        let isRTL = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft
        return UIBarButtonItem(image: UIImage(systemName: isRTL ? "chevron.right" : "chevron.left"), style: .plain, target: self, action: #selector(goBack))
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

    init(url: URL, matchingQueryKeys: [String] = [], contextDirectory: URL? = nil, filterURL: Bool = true) {
        self.url = url
        self.matchingQueryKeys = matchingQueryKeys
        self.contextDirectory = contextDirectory
        self.filterURL = filterURL
        let configuration = WKWebViewConfiguration()
        let handler = CelestiaScriptHandler()
        configuration.userContentController.add(handler, name: "iOSCelestia")
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        super.init(nibName: nil, bundle: nil)
        handler.delegate = self
    }

    deinit {
        // Maybe no longer needed?
        titleObservation?.invalidate()
        titleObservation = nil
        // Avoid leak https://stackoverflow.com/questions/26383031/
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "iOSCelestia")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.startAnimating()
        webView.load(URLRequest(url: url))
        webView.navigationDelegate = self

        navigationItem.leftBarButtonItem = goBackItem
        updateNavigation()

        titleObservation = webView.observe(\.title, options: .new, changeHandler: { [weak self] webView, _ in
            self?.navigationItem.title = webView.title
        })
    }

    private func updateNavigation() {
        goBackItem.isEnabled = webView.canGoBack
        if #available(iOS 16.0, *) {
#if !targetEnvironment(macCatalyst)
            // Hiding items might cause issue on Catalyst, so do not hide on Catalyst
            goBackItem.isHidden = !goBackItem.isEnabled
#endif
        } else {
            navigationItem.leftBarButtonItem = goBackItem.isEnabled ? goBackItem : nil
        }
    }

    @objc private func goBack() {
        webView.goBack()
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

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        updateNavigation()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.webViewLoadFailed()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        delegate?.webViewLoadFailed()
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
            self.navigationController?.pushViewController(ResourceItemViewController(item: item, needsRefetchItem: false), animated: true)
        }, decoder: ResourceItem.networkResponseDecoder)
    }

    func runDemo() {
        AppCore.shared.receiveAsync(.runDemo)
    }
}
