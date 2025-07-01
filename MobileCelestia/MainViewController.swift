//
// MainViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import CelestiaFoundation
import CelestiaUI
import LinkPresentation
import MessageUI
import UniformTypeIdentifiers
import UIKit

class MainViewController: UIViewController {
    enum LoadingStatus {
        case notLoaded
        case loading
        case loadingFailed
        case loaded
    }

    private enum Constants {
        static let feedbackEmailAddress = "celestia.mobile@outlook.com"
        static let feedbackGitHubLink = URL(string: "https://celestia.mobi/feedback")!
    }

    private(set) var celestiaController: CelestiaViewController!
    private lazy var loadingController = LoadingViewController(assetProvider: assetProvider)
    private lazy var actionViewController: ToolbarViewController = {
        let actions: [[AppToolbarAction]] = AppToolbarAction.persistentAction
        let controller = ToolbarViewController(actions: actions)
        controller.selectionHandler = { [weak self] action in
            guard let self, let ac = action as? AppToolbarAction else { return }
            self.toolbarActionSelected(ac)
        }
        #if !targetEnvironment(macCatalyst)
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = toolbarSlideInManager
        #endif
        return controller
    }()
    private var split: ToolbarSplitContainerController!

    private var status: LoadingStatus = .notLoaded
    private var retried: Bool = false

    #if !targetEnvironment(macCatalyst)
    private lazy var toolbarSlideInManager = PresentationManager(direction: UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .left : .right)
    private lazy var endSlideInManager = PresentationManager(direction: UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .left : .right, useSheetIfPossible: true)
    #endif

    private let core: AppCore
    private let executor: CelestiaExecutor
    private let userDefaults: UserDefaults
    private let requestHandler = RequestHandlerImpl()
    private let assetProvider = CelestiaAssetProvider()

    private let resourceManager = ResourceManager(extraAddonDirectory: UserDefaults.extraAddonDirectory, extraScriptDirectory: UserDefaults.extraScriptDirectory)

    private var viewControllerStack: [UIViewController] = []

    #if !targetEnvironment(macCatalyst)
    private var currentWindowSceneForMirroring: UIWindowScene?
    #endif

    private var scriptOrCelURL: UniformedURL?
    private var addonToOpen: String?
    private var guideToOpen: String?

    private var bottomToolbar: BottomControlViewController?
    private var bottomToolbarSizeConstraints = [NSLayoutConstraint]()

    private lazy var subscriptionManager = SubscriptionManager(userDefaults: userDefaults, requestHandler: requestHandler)
    private var subscriptionUpdateTask: Task<Void, Error>?

    private lazy var commonWebActionHandler = { [weak self] (action: CommonWebViewController.WebAction, viewController: UIViewController) in
        guard let self else { return }
        switch action {
        case .showSubscription:
            if #available(iOS 15, *) {
                self.showSubscription(for: viewController)
            }
        case .ack:
            break
        }
    }

    init(initialURL: UniformedURL?, screen: UIScreen, core: AppCore, executor: CelestiaExecutor, userDefaults: UserDefaults) {
        self.core = core
        self.executor = executor
        self.userDefaults = userDefaults
        super.init(nibName: nil, bundle: nil)
        celestiaController = CelestiaViewController(screen: screen, executor: executor, userDefaults: userDefaults, subscriptionManager: subscriptionManager, core: core)

        #if targetEnvironment(macCatalyst)
        let splitViewController = ToolbarSplitContainerController()
        #else
        let splitViewController = ToolbarSplitContainerController(style: .doubleColumn)
        #endif
        splitViewController.preferredDisplayMode = .secondaryOnly
        splitViewController.minimumPrimaryColumnWidth = ToolbarViewController.Constants.width
        splitViewController.maximumPrimaryColumnWidth = ToolbarViewController.Constants.width
        splitViewController.setSecondaryAndCompactViewController(celestiaController)
        split = splitViewController

        if let url = initialURL {
            receivedURL(url)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 15, *) {
            Task {
                await subscriptionManager.checkSubscriptionStatus()
            }
            subscriptionUpdateTask = subscriptionManager.checkPurchaseUpdates()
        }

        view.backgroundColor = .systemBackground

        celestiaController.delegate = self
        install(split)

        install(loadingController)

        NotificationCenter.default.addObserver(self, selector: #selector(newURLOpened(_:)), name: newURLOpenedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newAddonOpened(_:)), name: newAddonOpenedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newGuideOpened(_:)), name: newGuideOpenedNotificationName, object: nil)
        #if !targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(self, selector: #selector(newScreenConnected(_:)), name: newScreenConnectedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenDisconnected(_:)), name: screenDisconnectedNotificationName, object: nil)
        #endif
        NotificationCenter.default.addObserver(self, selector: #selector(presentHelp), name: showHelpNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showSettings), name: showPreferencesNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(requestOpenFile), name: requestOpenFileNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(menuBarAction(_:)), name: menuBarActionNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(requestRunScript(_:)), name: requestRunScriptNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(requestOpenBookmark(_:)), name: requestOpenBookmarkNotificationName, object: nil)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
         return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func updateViewConstraints() {
        if let bottomToolbar {
            let size = bottomToolbar.preferredContentSize
            if bottomToolbarSizeConstraints.isEmpty {
                bottomToolbarSizeConstraints = [
                    bottomToolbar.view.widthAnchor.constraint(equalToConstant: size.width),
                    bottomToolbar.view.heightAnchor.constraint(equalToConstant: size.height),
                ]
                NSLayoutConstraint.activate(bottomToolbarSizeConstraints)
            } else {
                bottomToolbarSizeConstraints[0].constant = size.width
                bottomToolbarSizeConstraints[1].constant = size.height
            }
        }
        super.updateViewConstraints()
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        guard container === bottomToolbar else {
            return
        }

        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()
    }
}

extension MainViewController {
    private func receivedURL(_ url: UniformedURL) {
        if url.url.isFileURL {
            scriptOrCelURL = url
        } else if url.url.scheme == "cel" {
            scriptOrCelURL = url
        } else if url.url.scheme == "celaddon" {
            guard let components = URLComponents(url: url.url, resolvingAgainstBaseURL: false) else { return }
            if components.host == "item" {
                guard let id = components.queryItems?.first(where: { $0.name == "item" })?.value else { return }
                addonToOpen = id
            }
        } else if url.url.scheme == "celguide" {
            guard let components = URLComponents(url: url.url, resolvingAgainstBaseURL: false) else { return }
            if components.host == "guide" {
                guard let id = components.queryItems?.first(where: { $0.name == "guide" })?.value else { return }
                guideToOpen = id
            }
        }
    }

    @objc private func requestOpenFile() {
        let types = Set([UTType(filenameExtension: "cel"), UTType(filenameExtension: "celx"), UTType(exportedAs: "space.celestia.script")]).compactMap { $0 }
        let browser = UIDocumentPickerViewController(forOpeningContentTypes: types)
        browser.allowsMultipleSelection = false
        browser.delegate = self
        presentAfterDismissCurrent(browser, animated: true)
    }

    @objc private func newURLOpened(_ notification: Notification) {
        guard let url = notification.userInfo?[newURLOpenedNotificationURLKey] as? UniformedURL else { return }
        receivedURL(url)
        guard status == .loaded else { return }
        openURLOrScriptOrGreeting()
    }

    @objc private func newAddonOpened(_ notification: Notification) {
        guard let addon = notification.userInfo?[newAddonOpenedNotificationIDKey] as? String else { return }
        addonToOpen = addon
        guard status == .loaded else { return }
        openURLOrScriptOrGreeting()
    }

    @objc private func newGuideOpened(_ notification: Notification) {
        guard let guide = notification.userInfo?[newGuideOpenedNotificationIDKey] as? String else { return }
        guideToOpen = guide
        guard status == .loaded else { return }
        openURLOrScriptOrGreeting()
    }

    private func openURLOrScriptOrGreeting() {
        func cleanup() {
            // Just clean up everything, only the first message gets presented
            addonToOpen = nil
            guideToOpen = nil
            scriptOrCelURL = nil
        }

        let onboardMessageDisplayed: Bool? = userDefaults[.onboardMessageDisplayed]
        if onboardMessageDisplayed == nil {
            userDefaults[.onboardMessageDisplayed] = true
            presentHelp()
            cleanup()
            return
        }

        if let url = scriptOrCelURL {
            if url.url.isFileURL {
                front?.showOption(CelestiaString("Run script?", comment: "Request user consent to run a script")) { [unowned self] (confirmed) in
                    guard confirmed else { return }
                    self.celestiaController.openURL(url)
                }
            } else if url.url.scheme == "cel" {
                front?.showOption(CelestiaString("Open URL?", comment: "Request user consent to open a URL")) { [unowned self] (confirmed) in
                    guard confirmed else { return }
                    self.celestiaController.openURL(url)
                }
            }
            cleanup()
            return
        }

        let locale = AppCore.language
        if let guide = guideToOpen {
            // Need to wrap it in a NavVC without NavBar to make sure
            // the scrolling behavior is correct on macCatalyst
            let vc = CommonWebViewController(executor: executor, resourceManager: resourceManager, url: .fromGuide(guideItemID: guide, language: locale), requestHandler: requestHandler, actionHandler: commonWebActionHandler, matchingQueryKeys: ["guide"])
            let nav = BaseNavigationController(rootViewController: vc)
            nav.setNavigationBarHidden(true, animated: false)
            showViewController(nav, key: guide, titleVisible: false)
            cleanup()
            return
        }

        if let addon = addonToOpen {
            Task {
                do {
                    let item = try await requestHandler.getMetadata(id: addon, language: locale)
                    let nav = ToolbarNavigationContainerController(rootViewController: ResourceItemViewController(executor: executor, resourceManager: resourceManager, item: item, needsRefetchItem: false, requestHandler: requestHandler, actionHandler: commonWebActionHandler))
                    self.showViewController(nav, key: addon, customToolbar: true)
                } catch {}
            }
            cleanup()
            return
        }

        // Check news
        Task {
            do {
                let item = try await requestHandler.getLatestMetadata(language: locale)
                if userDefaults[.lastNewsID] == item.id { return }
                let vc = CommonWebViewController(executor: executor, resourceManager: resourceManager, url: .fromGuide(guideItemID: item.id, language: locale), requestHandler: requestHandler, actionHandler: { [weak self] action, viewController in
                    guard let self else { return }
                    if case let CommonWebViewController.WebAction.ack(id) = action, id == item.id {
                        self.userDefaults[.lastNewsID] = id
                    } else {
                        self.commonWebActionHandler(action, viewController)
                    }
                }, matchingQueryKeys: ["guide"])
                let nav = BaseNavigationController(rootViewController: vc)
                nav.setNavigationBarHidden(true, animated: false)
                self.showViewController(nav, key: item.id, titleVisible: false)
            } catch {}
        }
    }
}

extension MainViewController {
    override func copy(_ sender: Any?) {
        Task {
            let url = await executor.get { $0.currentURL }
            UIPasteboard.general.url = URL(string: url)
        }
    }

    override func paste(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        var celURL: String?
        if pasteboard.hasURLs {
            if let url = pasteboard.url, url.scheme == "cel" {
                celURL = url.absoluteString
            }
        } else if pasteboard.hasStrings {
            if let string = pasteboard.string, string.starts(with: "cel:") {
                celURL = string
            }
        }
        if let url = celURL {
            executor.runAsynchronously { $0.go(to: url) }
        }
    }

    @objc private func menuBarAction(_ notification: Notification) {
        guard let action = notification.userInfo?[menuBarActionNotificationKey] as? MenuBarAction else {
            return
        }
        switch action {
        case .captureImage:
            shareImage()
        case .showAbout:
            let vc = AboutViewController(bundle: .app, defaultDirectoryURL: UserDefaults.defaultDataDirectory)
            showViewController(ToolbarNavigationContainerController(rootViewController: vc), customToolbar: true)
        case .selectSol:
            Task {
                await executor.receive(.home)
            }
        case .showGoto:
            presentGoTo()
        case .centerSelection:
            Task {
                await executor.receive(.center)
            }
        case .followSelection:
            Task {
                await executor.receive(.follow)
            }
        case .trackSelection:
            Task {
                await executor.receive(.track)
            }
        case .syncOrbitSelection:
            Task {
                await executor.receive(.syncOrbit)
            }
        case .gotoSelection:
            Task {
                await executor.receive(.goTo)
            }
        case .showFlightMode:
            showViewController(ToolbarNavigationContainerController(rootViewController: ObserverModeViewController(executor: executor)), customToolbar: true)
        case .showStarBrowser:
            showBrowser()
        case .showEclipseFinder:
            presentEventFinder()
        case .tenTimesFaster:
            Task {
                await executor.receive(.faster)
            }
        case .tenTimesSlower:
            Task {
                await executor.receive(.slower)
            }
        case .freezeTime:
            Task {
                await executor.receive(.playpause)
            }
        case .realTime:
            Task {
                await executor.receive(.currentTime)
            }
        case .reverseTime:
            Task {
                await executor.receive(.reverse)
            }
        case .showTimeSetting:
            showTimeSettings()
        case .splitHorizontally:
            Task {
                await executor.run { $0.charEnter(18) }
            }
        case .splitVertically:
            Task {
                await executor.run { $0.charEnter(21) }
            }
        case .deleteActiveView:
            Task {
                await executor.run { $0.charEnter(127) }
            }
        case .deleteOtherViews:
            Task {
                await executor.run { $0.charEnter(4) }
            }
        case .runDemo:
            Task {
                await executor.run { $0.runDemo() }
            }
        case .showOpenGLInfo:
            Task {
                let executor = self.executor
                let renderInfo = await executor.get {
                    executor.makeRenderContextCurrent()
                    return $0.renderInfo
                }
                let vc = TextViewController(title: CelestiaString("OpenGL Info", comment: ""), text: renderInfo)
                showViewController(ToolbarNavigationContainerController(rootViewController: vc), customToolbar: true)
            }
        case .getAddons:
            showOnlineAddons(category: nil)
        case .showInstalledAddons:
            presentInstalledAddons()
        case .addBookmark:
            Task {
                guard let currentBookmark = await executor.get({ $0.currentBookmark }) else { return }
                storeBookmarks(readBookmarks() + [currentBookmark])
                UIMenuSystem.main.setNeedsRebuild()
            }
        case .organizeBookmarks:
            presentFavorite(.bookmarks)
        case .reportBug:
            reportBug()
        case .suggestFeature:
            suggestFeature()
        case .celestiaPlus:
            if #available(iOS 15, *) {
                showSubscription()
            }
        case .getInfo:
            Task {
                let selection = await executor.get({ $0.simulation.selection })
                guard !selection.isEmpty else { return }
                showSelectionInfo(with: selection)
            }
        case .openAddonFolder:
            openFolder(UserDefaults.extraAddonDirectory)
        case .openScriptFolder:
            openFolder(UserDefaults.extraScriptDirectory)
        }
    }

    @objc private func requestRunScript(_ notification: Notification) {
        guard let script = notification.userInfo?[requestRunScriptNotificationKey] as? Script else { return }

        celestiaController.openURL(UniformedURL(url: URL(fileURLWithPath: script.filename), securityScoped: false))
    }

    @objc private func requestOpenBookmark(_ notification: Notification) {
        guard let bookmark = notification.userInfo?[requestOpenBookmarkNotificationKey] as? BookmarkNode else { return }
        guard let url = URL(string: bookmark.url) else { return }

        celestiaController.openURL(UniformedURL(url: url, securityScoped: false))
    }

    private func openFolder(_ url: URL?) {
        #if targetEnvironment(macCatalyst)
        guard let url else { return }
        MacBridge.openFolderURL(url)
        #endif
    }
}

extension MainViewController {
    #if !targetEnvironment(macCatalyst)
    @objc private func newScreenConnected(_ notification: Notification) {
        guard let windowScene = notification.object as? UIWindowScene else { return }
        // Avoid handling connecting to a new screen when we are working on a screen already
        guard currentWindowSceneForMirroring == nil else { return }

        currentWindowSceneForMirroring = windowScene
        showOption(CelestiaString("An external screen is connected, do you want to display Celestia on the external screen?", comment: "")) { [weak self] choice in
            guard choice, let self = self else { return }
            self.currentWindowSceneForMirroring = nil

            guard self.celestiaController.move(to: windowScene) else {
                self.showError(CelestiaString("Failed to connect to the external screen.", comment: ""))
                return
            }
        }
    }

    @objc private func screenDisconnected(_ notification: Notification) {
        guard let windowScene = notification.object as? UIWindowScene else { return }

        if windowScene == currentWindowSceneForMirroring {
            // The screen we are asking to connect is disconnected, dismiss
            // the presented alert controller
            dismiss(animated: true, completion: nil)
            currentWindowSceneForMirroring = nil
            return
        }

        guard celestiaController.isMirroring else {
            // Not mirroring, ignore
            return
        }

        guard windowScene.screen == celestiaController.displayScreen else {
            // Not the screen we expected
            return
        }

        guard celestiaController.moveBack(from: windowScene.screen) else {
            // Unable to move back from the screen
            return
        }
    }
    #endif
}

extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        #if targetEnvironment(macCatalyst)
        MacBridge.addRecentURL(url)
        #endif

        scriptOrCelURL = UniformedURL(url: url, securityScoped: true)
        openURLOrScriptOrGreeting()
    }
}

extension MainViewController: CelestiaControllerDelegate {
    func celestiaController(_ celestiaController: CelestiaViewController, loadingStatusUpdated status: String) {
        loadingController.update(with: String.localizedStringWithFormat(CelestiaString("Loading: %@", comment: "Celestia initialization, loading file"), status))
    }

    func celestiaController(_ celestiaController: CelestiaViewController, loadingFailedShouldRetry shouldRetry: @escaping (Bool) -> Void) {
        if retried {
            shouldRetry(false)
            return
        }
        showError(CelestiaString("Error loading data, fallback to original configuration.", comment: ""))
        retried = true
        userDefaults.saveConfigFile(nil)
        userDefaults.saveDataDirectory(nil)
        shouldRetry(true)
    }

    func celestiaControllerLoadingFailed(_ celestiaController: CelestiaViewController) {
        print("loading failed")

        self.status = .loadingFailed
        self.loadingController.update(with: CelestiaString("Loading Celestia failed…", comment: "Celestia loading failed"))
    }

    func celestiaControllerLoadingSucceeded(_ celestiaController: CelestiaViewController) {
        print("loading success")

        self.status = .loaded
        self.loadingController.remove()
        #if targetEnvironment(macCatalyst)
        split.setSidebarViewController(actionViewController)
        setupTouchBar()
        #endif
        UIMenuSystem.main.setNeedsRebuild()
        UIApplication.shared.isIdleTimerDisabled = true

        self.openURLOrScriptOrGreeting()
    }

    func celestiaControllerRequestShowActionMenu(_ celestiaController: CelestiaViewController) {
        #if targetEnvironment(macCatalyst)
        split.preferredDisplayMode = .oneBesideSecondary
        #else
        guard presentedViewController != actionViewController, !actionViewController.isBeingPresented else { return }
        presentAfterDismissCurrent(actionViewController, animated: true)
        #endif
    }

    func celestiaControllerRequestShowSearch(_ celestiaController: CelestiaViewController) {
        showSearch()
    }

    func celestiaController(_ celestiaController: CelestiaViewController, requestShowInfoWithSelection selection: Selection) {
        guard !selection.isEmpty else { return }
        showSelectionInfo(with: selection)
    }

    func celestiaController(_ celestiaController: CelestiaViewController, requestShowSubsystemWithSelection selection: Selection) {
        guard !selection.isEmpty else { return }
        showSubsystem(with: selection)
    }

    func celestiaController(_ celestiaController: CelestiaViewController, requestWebInfo webURL: URL) {
        showWeb(webURL)
    }

    func celestiaControllerCanAcceptKeyEvents(_ celestiaController: CelestiaViewController) -> Bool {
        #if targetEnvironment(macCatalyst)
        if traitCollection.activeAppearance != .active {
            return false
        }
        #endif
        return presentedViewController == nil
    }

    func celestiaControllerRequestGo(_ celestiaController: CelestiaViewController) {
        Task {
            await executor.receive(.goTo)
        }
    }

    private func toolbarActionSelected(_ action: AppToolbarAction) {
        switch action {
        case .setting:
            showSettings()
        case .search:
            showSearch()
        case .browse:
            showBrowser()
        case .time:
            presentTimeToolbar()
        case .script:
            presentScriptToolbar()
        case .camera:
            presentCameraControl()
        case .share:
            presentShare()
        case .favorite:
            presentFavorite(.main)
        case .help:
            presentHelp()
        case .home:
            Task {
                await executor.receive(.home)
            }
        case .event:
            presentEventFinder()
        case .addons:
            presentInstalledAddons()
        case .download:
            showOnlineAddons(category: nil)
        case .paperplane:
            presentGoTo()
        case .speedometer:
            presentSpeedControl()
        case .newsarchive:
            let baseURL = "https://celestia.mobi/news"
            var components = URLComponents(string: baseURL)!
            components.queryItems = [
                URLQueryItem(name: "lang", value: AppCore.language),
            ]
            let url = components.url!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        case .feedback:
            sendFeedback()
        case .plus:
            if #available(iOS 15, *) {
                showSubscription()
            }
        }
    }

    @available(iOS 15, *)
    private func showSubscription(for viewController: UIViewController? = nil) {
        let vc = SubscriptionManagerViewController(subscriptionManager: subscriptionManager, assetProvider: assetProvider)
        let nav = BaseNavigationController(rootViewController: vc)
        nav.setNavigationBarHidden(true, animated: false)
        showViewController(nav, titleVisible: false)
    }

    private func showOnlineAddons(category: CategoryInfo?) {
        showViewController(ResourceCategoriesViewController(category: category, executor: executor, resourceManager: resourceManager, subscriptionManager: subscriptionManager, requestHandler: requestHandler, actionHandler: commonWebActionHandler), key: category?.category, customToolbar: true)
    }

    private func sendFeedback() {
        showSelection(nil, options: [
            CelestiaString("Report a Bug", comment: ""),
            CelestiaString("Suggest a Feature", comment: ""),
        ], source: nil) { [weak self] index in
            guard let self, let index else { return }
            if index == 1 {
                self.suggestFeature()
            } else {
                self.reportBug()
            }
        }
    }

    private func reportBug() {
        guard MFMailComposeViewController.canSendMail() else {
            reportBugSuggestFeatureFallback()
            return
        }
        Task {
            do {
                try await reportBugAsync()
            } catch {
                reportBugSuggestFeatureFallback()
            }
        }
    }

    private func reportBugAsync() async throws {
        let parentURL = try URL.temp().appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)

        let screenshotURL = parentURL.appendingPathComponent("screenshot.png")
        let executor = self.executor
        let (renderInfo, url, screenshotSuccess) = await executor.get { core in
            executor.makeRenderContextCurrent()
            return (core.renderInfo, core.currentURL, core.screenshot(to: screenshotURL.path, type: .PNG))
        }
        let imageData = screenshotSuccess ? try? Data(contentsOf: screenshotURL) : nil
        let addonInfo = resourceManager.installedResources().map { "\($0.name)/\($0.id)" }.joined(separator: "\n")

        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = self
        vc.setToRecipients([Constants.feedbackEmailAddress])
        vc.setSubject(CelestiaString("Bug report for Celestia", comment: "Default email title for bug report"))
        vc.setMessageBody(CelestiaString("Please describe the issue and repro steps, if known.", comment: "Default email body for bug report"), isHTML: false)
        if let imageData {
            vc.addAttachmentData(imageData, mimeType: "image/png", fileName: "screenshot.png")
        }
        if let urlInfoData = url.data(using: .utf8) {
            vc.addAttachmentData(urlInfoData, mimeType: "text/plain", fileName: "urlinfo.txt")
        }
        if let renderInfoData = renderInfo.data(using: .utf8) {
            vc.addAttachmentData(renderInfoData, mimeType: "text/plain", fileName: "renderinfo.txt")
        }
        if let addonInfoData = addonInfo.data(using: .utf8) {
            vc.addAttachmentData(addonInfoData, mimeType: "text/plain", fileName: "addoninfo.txt")
        }

        if #available(iOS 15, *) {
            if let (transactionID, isSandbox) = subscriptionManager.transactionInfo() {
                let info = "\(transactionID) \(isSandbox)"
                if let infoData = info.data(using: .utf8) {
                    vc.addAttachmentData(infoData, mimeType: "text/plain", fileName: "transactionid.txt")
                }
            }
        }

        let bundle = Bundle.app
        let device = UIDevice.current

        var sysName = utsname()
        uname(&sysName)
        let machineMirror = Mirror(reflecting: sysName.machine)
        let model = machineMirror.children.reduce(into: String()) { identifier, element in
          guard let value = element.value as? Int8, value != 0 else { return }
          identifier += String(UnicodeScalar(UInt8(value)))
        }

        #if targetEnvironment(macCatalyst)
        let os = "Mac"
        #else
        let os = ProcessInfo.processInfo.isiOSAppOnMac ? "Mac (iOS)" : "iOS"
        #endif
        #if arch(x86_64)
        let arch = "x86_64"
        #elseif arch(arm64)
        let arch = "arm64"
        #endif
        let systemInfo =
"""
Application Version: \(bundle.shortVersion)(\(bundle.build))
Operating System: \(os)
Operating System Version: \(device.systemVersion)
Operating System Architecture \(arch)
Device Model: \(model)
"""
        if let systemInfoData = systemInfo.data(using: .utf8) {
            vc.addAttachmentData(systemInfoData, mimeType: "text/plain", fileName: "systeminfo.txt")
        }
        presentAfterDismissCurrent(vc, animated: true)
    }

    private func suggestFeature() {
        guard MFMailComposeViewController.canSendMail() else {
            reportBugSuggestFeatureFallback()
            return
        }
        Task {
            await suggestFeatureAsync()
        }
    }

    private func suggestFeatureAsync() async {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = self
        vc.setToRecipients([Constants.feedbackEmailAddress])
        vc.setSubject(CelestiaString("Feature suggestion for Celestia", comment: "Default email title for feature suggestion"))
        vc.setMessageBody(CelestiaString("Please describe the feature you want to see in Celestia.", comment: "Default email body for feature suggestion"), isHTML: false)
        if #available(iOS 15, *) {
            if let (transactionID, isSandbox) = subscriptionManager.transactionInfo() {
                let info = "\(transactionID) \(isSandbox)"
                if let infoData = info.data(using: .utf8) {
                    vc.addAttachmentData(infoData, mimeType: "text/plain", fileName: "transactionid.txt")
                }
            }
        }
        presentAfterDismissCurrent(vc, animated: true)
    }

    private func reportBugSuggestFeatureFallback() {
        UIApplication.shared.open(Constants.feedbackGitHubLink, options: [:], completionHandler: nil)
    }

    private func presentShare() {
        showSelection(nil, options: [CelestiaString("Image", comment: "Sharing option, image"), CelestiaString("URL", comment: "Sharing option, URL")], source: nil) { [weak self] index in
            guard let self = self, let index = index else { return }
            if index == 0 {
                self.shareImage()
            } else {
                self.shareURL()
            }
        }
    }

    private func shareImage() {
        let url: URL
        do {
            url = try URL.temp().appendingPathComponent("CelestiaScreenshot.png")
        } catch {
            showError(error.localizedDescription)
            return
        }
        let executor = self.executor
        Task {
            let success = await executor.get { core in
                executor.makeRenderContextCurrent()
                return core.screenshot(to: url.path, type: .JPEG)
            }

            if success {
                #if targetEnvironment(macCatalyst)
                self.saveFile(url)
                return
                #else
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    try? FileManager.default.removeItem(at: url)
                    self.showShareSheet(for: image)
                    return
                }
                #endif
            }
            self.showError(CelestiaString("Unable to generate image.", comment: "Failed to generate an image for sharing"))
        }
    }

    private func shareURL() {
        Task {
            let (url, name) = await executor.get { core in
                let selection = core.simulation.selection
                let name = core.simulation.universe.name(for: selection)
                let url = core.currentURL
                return (url, name)
            }

            self.shareURL(url, placeholder: name)
        }
    }

    private func presentFavorite(_ root: FavoriteRoot) {
        let controller = FavoriteCoordinatorController(executor: executor, root: root, extraScriptDirectoryPathProvider: {
            return UserDefaults.extraScriptDirectory?.path
        }, selected: { [unowned self] object in
            if let url = object as? URL {
                self.celestiaController.openURL(UniformedURL(url: url, securityScoped: false))
            } else if let destination = object as? Destination {
                self.executor.runAsynchronously { $0.simulation.goToDestination(destination) }
            }
        }, share: { object, viewController in
            guard let node = object as? BookmarkNode, node.isLeaf else { return }
            viewController.shareURL(node.url, placeholder: node.name)
        }, textInputHandler: { viewController, title, text in
            return await viewController.getTextInputDifferentiated(title, text: text)
        })
#if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600), customToolbar: true)
#else
        showViewController(controller)
#endif
    }

    private func presentScriptToolbar() {
        Task {
            await presentActionToolbar(for: [CelestiaAction.playpause, .cancelScript].map { .toolbarAction($0) })
        }
    }

    private func presentTimeToolbar() {
        let layoutDirectionDependentActions: [ToolbarAction]
        if UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft {
            layoutDirectionDependentActions = [
                CelestiaAction.faster,
                CelestiaAction.playpause,
                CelestiaAction.slower
            ]
        } else {
            layoutDirectionDependentActions = [
                CelestiaAction.slower,
                CelestiaAction.playpause,
                CelestiaAction.faster
            ]
        }
        Task {
            await presentActionToolbar(for: (layoutDirectionDependentActions + [CelestiaAction.reverse]).map { .toolbarAction($0) } + [BottomControlAction.custom(type: .showTimeSettings)])
        }
    }

    private func hideBottomToolbar() async {
        guard let bottomToolbar else { return }
        await UIViewPropertyAnimator.runningPropertyAnimator(withDuration: GlobalConstants.transitionDuration, delay: 0, options: [.curveLinear]) {
            bottomToolbar.view.alpha = 0
        }.addCompletion()
        bottomToolbar.remove()
        self.bottomToolbar = nil
        self.bottomToolbarSizeConstraints = []
    }

    private func presentActionToolbar(for actions: [BottomControlAction]) async {
        let newController = BottomControlViewController(actions: actions) { [unowned self] in
            Task {
                await self.hideBottomToolbar()
            }
        }
        newController.touchUpHandler = { [unowned self] action, inside in
            if let ac = action as? CelestiaAction {
                if inside {
                    Task {
                        await self.executor.receive(ac)
                    }
                }
            } else if let ac = action as? CelestiaContinuousAction {
                self.executor.runAsynchronously { core in
                    core.keyUp(ac.rawValue)
                }
            }
        }
        newController.touchDownHandler = { [unowned self] action in
            if let ac = action as? CelestiaContinuousAction {
                self.executor.runAsynchronously { core in
                    core.keyDown(ac.rawValue)
                }
            }
        }
        newController.customActionHandler = { [unowned self] type in
            switch type {
            case .showTimeSettings:
                self.showTimeSettings()
            }
        }
        #if targetEnvironment(macCatalyst)
        newController.touchBarActionConversionBlock = { (identifier) in
            return CelestiaAction(identifier)
        }
        #endif

        await hideBottomToolbar()

        addChild(newController)
        newController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newController.view)
        // fixed constraints
        NSLayoutConstraint.activate([
            newController.view.leadingAnchor.constraint(equalTo: celestiaController.view.safeAreaLayoutGuide.leadingAnchor),
            newController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            newController.view.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.8)
        ])
        // other constraints are updated in `updateViewConstraints`
        newController.didMove(toParent: self)
        bottomToolbar = newController
        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()

        newController.view.alpha = 0
        await UIViewPropertyAnimator.runningPropertyAnimator(withDuration: GlobalConstants.transitionDuration, delay: 0, options: [.curveLinear]) {
            newController.view.alpha = 1.0
        }.addCompletion()
    }

    private func presentCameraControl() {
        #if !targetEnvironment(macCatalyst)
        let vc = CameraControlViewController(executor: executor, gyroscopeSettings: celestiaController.gyroscopeSettings)
        #else
        let vc = CameraControlViewController(executor: executor)
        #endif
        let controller = ToolbarNavigationContainerController(rootViewController: vc)
        showViewController(controller, customToolbar: true)
    }

    @objc private func presentHelp() {
        let vc = HelpViewController(executor: executor, resourceManager: resourceManager, requestHandler: requestHandler, assetProvider: assetProvider, actionHandler: commonWebActionHandler)
        showViewController(vc, titleVisible: false)
    }

    private func presentEventFinder() {
        showViewController(EventFinderCoordinatorViewController(executor: executor, eventHandler: { [weak self] eclipse in
            guard let self else { return }
            self.executor.runAsynchronously { $0.simulation.goToEclipse(eclipse) }
        }, textInputHandler: { viewController, title in
            return await viewController.getTextInputDifferentiated(title)
        }, dateInputHandler: { viewController, title, format in
            return await viewController.getDateInputDifferentiated(title, format: format)
        }), customToolbar: true)
    }

    private func presentInstalledAddons() {
        let controller = ResourceViewController(executor: executor, resourceManager: resourceManager, requestHandler: requestHandler, actionHandler: commonWebActionHandler) { [weak self] in
            guard let self else { return }
            self.showOnlineAddons(category: nil)
        }
        showViewController(controller, customToolbar: true)
    }

    private func presentGoTo() {
        showViewController(GoToContainerViewController(executor: executor, locationHandler: { [weak self] location in
            self?.executor.runAsynchronously { $0.simulation.go(to: location) }
        }, textInputHandler: { viewController, title, text, keyboardType in
            return await viewController.getTextInputDifferentiated(title, text: text, keyboardType: keyboardType)
        }), customToolbar: true)
    }

    private func presentSpeedControl() {
        let layoutDirectionDependentActions: [ToolbarAction]
        if UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft {
            layoutDirectionDependentActions = [
                CelestiaContinuousAction.travelFaster,
                CelestiaContinuousAction.travelSlower,
            ]
        } else {
            layoutDirectionDependentActions = [
                CelestiaContinuousAction.travelSlower,
                CelestiaContinuousAction.travelFaster,
            ]
        }

        Task {
            await presentActionToolbar(for: layoutDirectionDependentActions.map { .toolbarAction($0) } + [
                .toolbarAction(CelestiaAction.stop),
                .toolbarAction(CelestiaAction.reverseSpeed),
                .groupedActions(accessibilityLabel: CelestiaString("Speed Presets", comment: "Action to show a list of presets in speed"), actions: [
                    CelestiaContinuousAction.f2,
                    CelestiaContinuousAction.f3,
                    CelestiaContinuousAction.f4,
                    CelestiaContinuousAction.f5,
                    CelestiaContinuousAction.f6,
                    CelestiaContinuousAction.f7,
                ])
            ])
        }
    }

    private func showSelectionInfo(with selection: Selection) {
        let viewController = createSelectionInfoViewController(with: selection, showNavigationTitle: false, backgroundColor: .secondarySystemBackground)
        showViewController(viewController, titleVisible: false)
    }

    private func createSelectionInfoViewController(with selection: Selection, showNavigationTitle: Bool, backgroundColor: UIColor) -> InfoViewController {
        let controller = InfoViewController(info: selection, core: core, executor: executor, showNavigationTitle: showNavigationTitle, backgroundColor: backgroundColor)
        controller.selectionHandler = { [weak self] selection, action in
            guard let self else { return }
            switch action {
            case .subsystem:
                self.showSubsystem(with: selection)
            }
        }
        return controller
    }

    private func showMarkMenu(with selection: Selection, with sender: UIView, viewController: UIViewController) {
        let options = (0...MarkerRepresentation.crosshair.rawValue).map{ MarkerRepresentation(rawValue: $0)?.localizedTitle ?? "" } + [CelestiaString("Unmark", comment: "Unmark an object")]
        viewController.showSelection(CelestiaString("Mark", comment: "Mark an object"), options: options, source: .view(view: sender, sourceRect: nil)) { [weak self] index in
            guard let self = self, let index = index else { return }
            if let marker = MarkerRepresentation(rawValue: UInt(index)) {
                Task {
                    await self.executor.mark(selection, markerType: marker)
                }
            } else {
                self.executor.runAsynchronously { $0.simulation.universe.unmark(selection) }
            }
        }
    }

    private func showAlternateSurfaces(of selection: Selection, with sender: UIView, viewController: UIViewController) {
        guard let alternativeSurfaces = selection.body?.alternateSurfaceNames, alternativeSurfaces.count > 0 else { return }
        viewController.showSelection(CelestiaString("Alternate Surfaces", comment: "Alternative textures to display"), options: [CelestiaString("Default", comment: "")] + alternativeSurfaces, source: .view(view: sender, sourceRect: nil)) { [weak self] index in
            guard let self = self, let index = index else { return }

            if index == 0 {
                self.executor.runAsynchronously { $0.simulation.activeObserver.displayedSurface = "" }
                return
            }
            self.executor.runAsynchronously { $0.simulation.activeObserver.displayedSurface = alternativeSurfaces[index - 1] }
        }
    }

    private func showWeb(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func showSubsystem(with selection: Selection) {
        guard let entry = selection.object else { return }
        let browserItem = BrowserItem(name: core.simulation.universe.name(for: selection), alternativeName: nil, catEntry: entry, provider: core.simulation.universe)
        let controller = SubsystemBrowserCoordinatorViewController(item: browserItem, selection: { [unowned self] (selection) -> UIViewController in
            return self.createSelectionInfoViewController(with: selection, showNavigationTitle: true, backgroundColor: .systemBackground)
        }, showAddonCategory: { [weak self] category in
            guard let self else { return }
            self.showOnlineAddons(category: category)
        })
        showViewController(controller, customToolbar: true)
    }

    private func showTimeSettings() {
        let vc = TimeSettingViewController(core: core, executor: executor, dateInputHandler: { viewController, title, format in
            return await viewController.getDateInputDifferentiated(title, format: format)
        }) { viewController, title, keyboardType in
            return await viewController.getTextInputDifferentiated(title, keyboardType: keyboardType)
        }
        showViewController(ToolbarNavigationContainerController(rootViewController: vc), customToolbar: true)
    }

    @objc private func showSettings() {
        let executor = self.executor
        let controller = SettingsCoordinatorController(
            core: core,
            executor: executor,
            userDefaults: userDefaults,
            bundle: .app,
            defaultDataDirectory: UserDefaults.defaultDataDirectory,
            settings: mainSetting,
            frameRateContext: FrameRateSettingContext(frameRateUserDefaultsKey: UserDefaultsKey.frameRate.rawValue),
            dataLocationContext: DataLocationSettingContext(
                userDefaults: userDefaults,
                dataDirectoryUserDefaultsKey: UserDefaultsKey.dataDirPath.rawValue,
                configFileUserDefaultsKey: UserDefaultsKey.configFile.rawValue,
                defaultDataDirectoryURL: UserDefaults.defaultDataDirectory,
                defaultConfigFileURL: UserDefaults.defaultConfigFile
            ),
            fontContext: FontSettingContext(
                normalFontPathKey: UserDefaultsKey.normalFontPath.rawValue,
                normalFontIndexKey: UserDefaultsKey.normalFontIndex.rawValue,
                boldFontPathKey: UserDefaultsKey.boldFontPath.rawValue,
                boldFontIndexKey: UserDefaultsKey.boldFontIndex.rawValue
            ),
            toolbarContext: ToolbarSettingContext(toolbarActionsKey: UserDefaultsKey.toolbarItems.rawValue),
            assetProvider: assetProvider,
            actionHandler: { [weak self]
                settingsAction in
                guard let self else { return }
                switch settingsAction {
                case .refreshFrameRate(let newFrameRate):
                    self.userDefaults[.frameRate] = newFrameRate
                    self.celestiaController.updateFrameRate(newFrameRate)
                }
            }, dateInputHandler: { viewController, title, format in
                return await viewController.getDateInputDifferentiated(title, format: format)
            }, textInputHandler: { viewController, title, keyboardType in
                return await viewController.getTextInputDifferentiated(title, keyboardType: keyboardType)
            }, rendererInfoProvider: {
                return await executor.get { core in
                    executor.makeRenderContextCurrent()
                    return core.renderInfo
                }
            }, screenProvider: { [weak self] in
                return self?.celestiaController.displayScreen
            }, subscriptionManager: subscriptionManager, openSubscriptionManagement: { [weak self] viewController in
                guard let self else { return }
                if #available(iOS 15, *) {
                    self.showSubscription(for: viewController)
                }
            }
        )
        #if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600), customToolbar: true)
        #else
        showViewController(controller)
        #endif
    }

    private func showSearch() {
        let controller = SearchCoordinatorController(executor: executor) { [unowned self] info in
            return self.createSelectionInfoViewController(with: info, showNavigationTitle: false, backgroundColor: .systemBackground)
        }
        #if targetEnvironment(macCatalyst)
        showViewController(controller, customToolbar: true)
        #else
        showViewController(controller)
        #endif
    }

    private func showBrowser() {
        let controller = BrowserContainerViewController(assetProvider: assetProvider, selected: { [unowned self] (info) in
            return self.createSelectionInfoViewController(with: info, showNavigationTitle: true, backgroundColor: .systemBackground)
        }, showAddonCategory: { [weak self] category in
            guard let self else { return }
            self.showOnlineAddons(category: category)
        }, executor: executor)
        #if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600), customToolbar: true)
        #else
        showViewController(controller)
        #endif
    }

    private func showViewController(_ viewController: UIViewController,
                                    key: String? = nil,
                                    iOSPreferredSize: CGSize = CGSize(width: 320, height: 320),
                                    macOSPreferredSize: CGSize = CGSize(width: 500, height: 600),
                                    titleVisible: Bool = true,
                                    customToolbar: Bool = false) {
        #if targetEnvironment(macCatalyst)
        PanelSceneDelegate.present(viewController, key: key, preferredSize: macOSPreferredSize, titleVisible: titleVisible, customToolbar: customToolbar)
        #else
        viewController.preferredContentSize = iOSPreferredSize
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = endSlideInManager

        presentAfterDismissCurrent(viewController, animated: true)
        #endif
    }
}

extension UIViewController {
    func presentAfterDismissCurrent(_ viewController: UIViewController, animated: Bool) {
        callAfterDismissCurrent(animated: animated) { [weak self] in
            self?.present(viewController, animated: animated)
        }
    }
}

#if targetEnvironment(macCatalyst)
extension MainViewController {
    private func saveFile(_ url: URL) {
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: false)
        picker.shouldShowFileExtensions = true
        picker.allowsMultipleSelection = false
        presentAfterDismissCurrent(picker, animated: true)
    }
}
#endif

#if targetEnvironment(macCatalyst)
extension MainViewController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let action = AppToolbarAction(rawValue: itemIdentifier.rawValue) else { return nil }
        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: UIBarButtonItem())
        toolbarItem.label = action.title ?? ""
        toolbarItem.toolTip = action.title
        toolbarItem.image = action.toolBarImage
        toolbarItem.target = self
        toolbarItem.action = #selector(toolbarButtonItemClicked(_:))

        return toolbarItem
    }

    private func defaultToolbarIdentifiers() -> [NSToolbarItem.Identifier] {
        let rightActions: [AppToolbarAction] = [.share, .search]
        return
            [AppToolbarAction.browse, .favorite, .home, .paperplane].map { NSToolbarItem.Identifier($0.rawValue) } +
            [.flexibleSpace] +
            rightActions.map { NSToolbarItem.Identifier($0.rawValue) }
    }

    private func availableIdentifiers() -> [NSToolbarItem.Identifier] {
        let actions = AppToolbarAction.persistentAction.reduce([AppToolbarAction](), { $0 + $1 })
        return actions.map { NSToolbarItem.Identifier(rawValue: $0.rawValue) } + [.flexibleSpace, .space]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return defaultToolbarIdentifiers()
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return availableIdentifiers()
    }

    @objc private func toolbarButtonItemClicked(_ sender: NSToolbarItem) {
        guard let action = AppToolbarAction(rawValue: sender.itemIdentifier.rawValue) else { return }
        toolbarActionSelected(action)
    }

    @objc private func undoOrRedo(_ sender: NSToolbarItemGroup) {
        if sender.selectedIndex == 0 {
            executor.runAsynchronously { $0.back() }
        } else {
            executor.runAsynchronously { $0.forward() }
        }
    }
}

extension MainViewController: NSTouchBarDelegate {
    private func setupTouchBar() {
        touchBar = nil
    }

    override func makeTouchBar() -> NSTouchBar? {
        guard status == .loaded else { return nil }
        let tbar = NSTouchBar()
        tbar.defaultItemIdentifiers = availableIdentifiers().map { NSTouchBarItem.Identifier($0.rawValue) }
        tbar.delegate = self
        return tbar
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        guard let action = AppToolbarAction(rawValue: identifier.rawValue) else { return nil }
        if let image = action.touchBarImage {
            return NSButtonTouchBarItem(identifier: identifier, image: image, target: self, action: #selector(touchBarButtonItemClicked(_:)))
        }
        return NSButtonTouchBarItem(identifier: identifier, title: action.title ?? "", target: self, action: #selector(touchBarButtonItemClicked(_:)))
    }

    @objc private func touchBarButtonItemClicked(_ sender: NSTouchBarItem) {
        guard let action = AppToolbarAction(rawValue: sender.identifier.rawValue) else { return }
        toolbarActionSelected(action)
    }
}

extension AppToolbarAction {
    var touchBarImage: UIImage? {
        return toolBarImage
    }
}

extension AppToolbarAction {
    var toolBarImage: UIImage? {
        return image
    }
}
#endif

extension CelestiaAction: ToolbarAction {
    var title: String? {
        return description
    }
}

extension CelestiaContinuousAction: ToolbarAction {}

#if targetEnvironment(macCatalyst)
extension CelestiaAction: ToolbarTouchBarAction {
    var touchBarImage: UIImage? {
        return image
    }

    var touchBarItemIdentifier: NSTouchBarItem.Identifier {
        return NSTouchBarItem.Identifier(rawValue: "\(rawValue)")
    }

    init?(_ touchBarItemIdentifier: NSTouchBarItem.Identifier) {
        guard let rawValue = Int8(touchBarItemIdentifier.rawValue) else { return nil }
        self.init(rawValue: rawValue)
    }
}
#endif

extension MainViewController: @preconcurrency MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

#if targetEnvironment(macCatalyst)
extension MainViewController: ToolbarContainerViewController {
    var nsToolbar: NSToolbar? {
        get { split.nsToolbar }
        set { split.nsToolbar = newValue }
    }

    func updateToolbar(for viewController: UIViewController) {
        split.updateToolbar(for: viewController)
    }
}
#endif

struct CelestiaAssetProvider: AssetProvider {
    func image(for image: AssetImage) -> UIImage {
        return UIImage(resource: imageResource(for: image))
    }

    private func imageResource(for image: AssetImage) -> ImageResource {
        switch image {
        case .loadingIcon:
            .loadingIcon
        case .browserTabDso:
            if #available(iOS 26, *) {
                .symbolGalaxy
            } else {
                .browserTabDso
            }
        case .browserTabSso:
            if #available(iOS 26, *) {
                .symbolSun
            } else {
                .browserTabSso
            }
        case .browserTabStar:
            if #available(iOS 26, *) {
                .symbolStar
            } else {
                .browserTabStar
            }
        case .tutorialSwitchMode:
            .tutorialSwitchMode
        }
    }
}
