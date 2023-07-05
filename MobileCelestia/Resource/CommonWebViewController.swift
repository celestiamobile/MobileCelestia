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

@MainActor
protocol CommonWebViewControllerDelegate: AnyObject {
    func webViewLoadFailed()
}

class CommonWebViewController: UIViewController {
    private let url: URL
    private let matchingQueryKeys: [String]
    private let contextDirectory: URL?
    private let filterURL: Bool
    private var titleObservation: NSKeyValueObservation?

    @Injected(\.executor) private var executor

    weak var delegate: CommonWebViewControllerDelegate?

    var ackHandler: ((String) -> Void)?

    private let webView: WKWebView

    private lazy var goBackItem: UIBarButtonItem = {
        let isRTL = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft
        return UIBarButtonItem(image: UIImage(systemName: isRTL ? "chevron.right" : "chevron.left"), style: .plain, target: self, action: #selector(goBack))
    }()

    private lazy var activityIndicator = UIActivityIndicatorView(style: .large)

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
            guard let self else { return }
            Task.detached { @MainActor in
                self.navigationItem.title = webView.title
            }
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
    nonisolated private func isURLAllowed(_ url: URL) -> Bool {
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

    nonisolated func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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
            Task.detached { @MainActor in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        Task.detached { @MainActor in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            self.updateNavigation()
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task.detached { @MainActor in
            self.delegate?.webViewLoadFailed()
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task.detached { @MainActor in
            self.delegate?.webViewLoadFailed()
        }
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

        Task {
            guard let data = content.data(using: .utf8) else { return }
            do {
                try await data.write(to: scriptURL)
                await self.executor.run { core in
                    core.runScript(at: scriptURL.path)
                }
            } catch {}
        }
    }

    func shareURL(title: String, url: URL) {
        showShareSheet(for: url)
    }

    func receivedACK(id: String) {
        ackHandler?(id)
    }

    func openAddonNext(id: String) {
        let requestURL = apiPrefix + "/resource/item"
        Task {
            do {
                let item: ResourceItem = try await RequestHandler.getDecoded(url: requestURL, parameters: ["lang": AppCore.language, "item": id], decoder: ResourceItem.networkResponseDecoder)
                self.navigationController?.pushViewController(ResourceItemViewController(item: item, needsRefetchItem: false), animated: true)
            } catch {}
        }
    }

    func runDemo() {
        Task {
            await executor.receive(.runDemo)
        }
    }
}

extension Data {
    func write(to url: URL, options: Data.WritingOptions = []) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global().async {
                do {
                    try self.write(to: url, options: options)
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
