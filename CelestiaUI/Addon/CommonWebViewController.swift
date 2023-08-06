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
import MWRequest
import UIKit
import WebKit

@MainActor
protocol CommonWebViewControllerDelegate: AnyObject {
    func webViewLoadFailed()
}

public class CommonWebViewController: UIViewController {
    private let url: URL
    private let matchingQueryKeys: [String]
    private let contextDirectory: URL?
    private let filterURL: Bool
    private var titleObservation: NSKeyValueObservation?

    private let executor: AsyncProviderExecutor
    private let resourceManager: ResourceManager

    weak var delegate: CommonWebViewControllerDelegate?

    public var ackHandler: ((String) -> Void)?

    private let webView: WKWebView

    private lazy var goBackItem: UIBarButtonItem = {
        let isRTL = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft
        return UIBarButtonItem(image: UIImage(systemName: isRTL ? "chevron.right" : "chevron.left"), style: .plain, target: self, action: #selector(goBack))
    }()

    #if targetEnvironment(macCatalyst)
    private lazy var toolbarBackItem: NSToolbarItem = {
        return NSToolbarItem(backItemIdentifier: .back, target: self, action: #selector(goBack))
    }()
    #endif

    private lazy var activityIndicator = UIActivityIndicatorView(style: .large)

    public override func loadView() {
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

    public init(executor: AsyncProviderExecutor, resourceManager: ResourceManager, url: URL, matchingQueryKeys: [String] = [], contextDirectory: URL? = nil, filterURL: Bool = true) {
        self.executor = executor
        self.resourceManager = resourceManager
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

    public override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.startAnimating()
        webView.load(URLRequest(url: url))
        webView.navigationDelegate = self

        navigationItem.leftBarButtonItem = goBackItem
        updateNavigation()

        titleObservation = webView.observe(\.title, options: .new, changeHandler: { [weak self] webView, _ in
            guard let self else { return }
            Task.detached { @MainActor in
                self.title = webView.title
            }
        })
    }

    private func updateNavigation() {
#if !targetEnvironment(macCatalyst)
        goBackItem.isEnabled = webView.canGoBack
        if #available(iOS 16.0, *) {
            goBackItem.isHidden = !goBackItem.isEnabled
        }
#else
        toolbarBackItem.isEnabled = webView.canGoBack
        updateToolbarIfNeeded()
#endif
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

    public nonisolated func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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

    public nonisolated func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        Task.detached { @MainActor in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            self.updateNavigation()
        }
    }

    public nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task.detached { @MainActor in
            self.delegate?.webViewLoadFailed()
        }
    }

    public nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
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
        Task {
            do {
                let item: ResourceItem = try await ResourceItem.getMetadata(id: id, language: AppCore.language)
                self.navigationController?.pushViewController(ResourceItemViewController(executor: self.executor, resourceManager: self.resourceManager, item: item, needsRefetchItem: false), animated: true)
            } catch {}
        }
    }

    func runDemo() {
        Task {
            await executor.run { $0.receive(.runDemo) }
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

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: GoToInputViewController.self).bundleIdentifier!
    fileprivate static let back = NSToolbarItem.Identifier.init("\(prefix).web.back")
}

extension CommonWebViewController: ToolbarAwareViewController {
    public func insertSpaceBeforeToolbarItems(for toolbarContainerViewController: ToolbarContainerViewController) -> Bool {
        return false
    }

    public func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier] {
        return webView.canGoBack ? [.back] : []
    }

    public func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        if itemIdentifier == .back {
            return toolbarBackItem
        }
        return nil
    }
}
#endif


