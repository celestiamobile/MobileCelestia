// CommonWebViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaFoundation
import UIKit
import WebKit

@MainActor
protocol CommonWebViewControllerDelegate: AnyObject {
    func webViewLoadFailed()
    func webViewNavigationItemUpdated(_ navigationItem: UINavigationItem)
}

public class CommonWebViewController: UIViewController {
    public nonisolated static var supportsNativeGuideHeader: Bool {
        #if os(visionOS)
        return false
        #else
        if #available(anyAppleOS 26.0, *) {
            return true
        }
        return false
        #endif
    }

    public enum WebAction: Sendable {
        case showSubscription
        case ack(id: String)
    }

    private var hasLoadedInitialPage = false
    private var url: URL
    private let matchingQueryKeys: [String]
    private let contextDirectory: URL?
    private let filterURL: Bool
    private var titleObservation: NSKeyValueObservation?
    private let showsGuideHeader: Bool
    private var pageInfo: SendACKContext?

    private var guideShareURL: URL? {
        guard showsGuideHeader && Self.supportsNativeGuideHeader else { return nil }
        return pageInfo?.shareURL
    }

    private let executor: AsyncProviderExecutor
    private let resourceManager: ResourceManager

    private let actionHandler: ((WebAction, UIViewController) -> Void)?
    private let requestHandler: RequestHandler

    weak var delegate: CommonWebViewControllerDelegate?

    private let webView: WKWebView

    private lazy var goBackItem: UIBarButtonItem = {
        let isRTL = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft
        return UIBarButtonItem(image: UIImage(systemName: isRTL ? "chevron.right" : "chevron.left"), style: .plain, target: self, action: #selector(goBack))
    }()

    private lazy var shareGuideItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareGuide(_:)))

    #if targetEnvironment(macCatalyst)
    private lazy var toolbarBackItem: NSToolbarItem = {
        return NSToolbarItem(backItemIdentifier: .back, target: self, action: #selector(goBack))
    }()
    private lazy var toolbarShareItem = NSSharingServicePickerToolbarItem(itemIdentifier: .share)
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

    public init(executor: AsyncProviderExecutor, resourceManager: ResourceManager, url: URL, requestHandler: RequestHandler, actionHandler: ((WebAction, UIViewController) -> Void)?, matchingQueryKeys: [String] = [], contextDirectory: URL? = nil, filterURL: Bool = true, showsGuideHeader: Bool = false) {
        self.executor = executor
        self.resourceManager = resourceManager
        self.url = url
        self.actionHandler = actionHandler
        self.requestHandler = requestHandler
        self.matchingQueryKeys = matchingQueryKeys
        self.contextDirectory = contextDirectory
        self.filterURL = filterURL
        self.showsGuideHeader = showsGuideHeader
        let configuration = WKWebViewConfiguration()
        configuration.limitsNavigationsToAppBoundDomains = true
        let handler = CelestiaScriptHandler()
        configuration.userContentController.add(handler, name: "iOSCelestia")
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        super.init(nibName: nil, bundle: nil)
        handler.delegate = self
    }

    deinit {
        // Maybe no longer needed?
        titleObservation?.invalidate()
        titleObservation = nil
        // Avoid leak https://stackoverflow.com/questions/26383031/
        let webView = self.webView
        Task { @MainActor in
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "iOSCelestia")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = goBackItem
        titleObservation = webView.observe(\.title, options: .new, changeHandler: { [weak self] webView, _ in
            guard let self else { return }
            Task.detached { @MainActor in
                self.updatePageTitle()
            }
        })
    }

    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        if !hasLoadedInitialPage {
            hasLoadedInitialPage = true
            webView.frame = view.bounds /// WebView's frame might be not decided yet
            activityIndicator.startAnimating()
            webView.load(URLRequest(url: url))
            webView.navigationDelegate = self
            #if DEBUG
            if #available(iOS 16.4, visionOS 1, *) {
                webView.isInspectable = true
            }
            #endif

            updateNavigation()
        }
    }

    private func updateNavigation() {
        goBackItem.isEnabled = webView.canGoBack
        goBackItem.isHidden = !goBackItem.isEnabled
#if targetEnvironment(macCatalyst)
        toolbarBackItem.isEnabled = webView.canGoBack
        updateToolbarIfNeeded()
#endif
        delegate?.webViewNavigationItemUpdated(navigationItem)
    }

    private func updatePageTitle() {
        if showsGuideHeader && Self.supportsNativeGuideHeader {
            title = pageInfo?.title ?? webView.title ?? title
            windowTitle = title
            windowSubtitle = pageInfo?.subtitle?.isEmpty == false ? pageInfo?.subtitle : nil
        } else {
            title = webView.title
            windowTitle = title
            windowSubtitle = nil
        }
        #if !os(visionOS)
        if showsGuideHeader, #available(anyAppleOS 26.0, *) {
            navigationItem.subtitle = windowSubtitle
            navigationItem.rightBarButtonItem = guideShareURL != nil ? shareGuideItem : nil
        }
        #endif
        #if targetEnvironment(macCatalyst)
        toolbarShareItem.activityItemsConfiguration = guideShareURL.map {
            UIActivityItemsConfiguration(objects: [$0 as NSURL])
        }
        toolbarShareItem.isEnabled = guideShareURL != nil
        updateToolbarIfNeeded()
        #endif
        delegate?.webViewNavigationItemUpdated(navigationItem)
    }

    private func handleLoadFailure() {
        if showsGuideHeader && Self.supportsNativeGuideHeader {
            pageInfo = nil
            updatePageTitle()
        }
        delegate?.webViewLoadFailed()
    }

    @objc private func shareGuide(_ sender: UIBarButtonItem) {
        guard let shareURL = guideShareURL else { return }
        showShareSheet(for: shareURL, source: .barButtonItem(barButtonItem: sender))
    }

    @objc private func goBack() {
        webView.goBack()
    }

    public func reload(_ url: URL) {
        self.url = url
        webView.load(URLRequest(url: url))
    }
}

extension CommonWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if showsGuideHeader && Self.supportsNativeGuideHeader {
            pageInfo = nil
            updatePageTitle()
        }
    }

    private func isURLAllowed(_ url: URL) -> Bool {
        let comp1 = URLComponents(url: self.url, resolvingAgainstBaseURL: false)!
        let comp2 = URLComponents(url: url, resolvingAgainstBaseURL: false)!
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

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if !filterURL {
            return .allow
        }
        if navigationAction.targetFrame?.isMainFrame == false {
            return .allow
        }
        guard let url = navigationAction.request.url else {
            return .cancel
        }

        if isURLAllowed(url) {
            return .allow
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return .cancel
        }
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        updateNavigation()
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleLoadFailure()
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoadFailure()
    }
}

extension CommonWebViewController: CelestiaScriptHandlerDelegate {
    func runScript(type: String, content: String, name: String?, location: String?) {
        guard ["cel", "celx"].contains(type) else { return }

        let scriptURL: URL
        let scriptFileName = (name ?? UUID().uuidString) + "." + type
        guard let tempURL = try? URL.temp().appendingPathComponent(scriptFileName) else { return }
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

    func shareURL(title: String, url: URL, rect: CGRect) {
        if !rect.isEmpty {
            let elementRect = CGRect(x: rect.minX + webView.scrollView.adjustedContentInset.left, y: rect.minY + webView.scrollView.adjustedContentInset.top, width: rect.width, height: rect.height)
            showShareSheet(for: url, source: .view(view: webView, sourceRect: elementRect))
        } else {
            showShareSheet(for: url)
        }
    }

    func receivedACK(context: SendACKContext) {
        if showsGuideHeader && Self.supportsNativeGuideHeader {
            pageInfo = context
            updatePageTitle()
        }
        actionHandler?(.ack(id: context.id), self)
    }

    func openAddonNext(id: String) {
        Task {
            do {
                let item: ResourceItem = try await requestHandler.getMetadata(id: id, language: AppCore.language)
                guard let navigationController else { return }
                // Do not push another ResourceItemFragment if it is the top
                if !(navigationController.topViewController is ResourceItemViewController) {
                    navigationController.pushViewController(ResourceItemViewController(executor: self.executor, resourceManager: self.resourceManager, item: item, requestHandler: requestHandler, actionHandler: self.actionHandler), animated: true)
                }
            } catch {}
        }
    }

    func runDemo() {
        Task {
            await executor.run { $0.runDemo() }
        }
    }

    func openSubscriptionPage() {
        actionHandler?(.showSubscription, self)
    }
}

extension Data {
    func write(to url: URL, options: Data.WritingOptions = []) async throws {
        try await Task.detached(priority: .background) {
            do {
                try self.write(to: url, options: options)
            } catch {
                throw error
            }
        }.value
    }
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: GoToInputViewController.self).bundleIdentifier!
    fileprivate static let back = NSToolbarItem.Identifier.init("\(prefix).web.back")
    fileprivate static let share = NSToolbarItem.Identifier.init("\(prefix).web.share")
}

extension CommonWebViewController: ToolbarAwareViewController {
    public func insertSpaceBeforeToolbarItems(for toolbarContainerViewController: ToolbarContainerViewController) -> Bool {
        return false
    }

    public func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier] {
        var items: [NSToolbarItem.Identifier] = webView.canGoBack ? [.back] : []
        if guideShareURL != nil {
            items += [.flexibleSpace, .share]
        }
        return items
    }

    public func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        if itemIdentifier == .back {
            return toolbarBackItem
        }
        if itemIdentifier == .share {
            return toolbarShareItem
        }
        return nil
    }
}
#endif

