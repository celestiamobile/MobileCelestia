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
import LinkPresentation
import UniformTypeIdentifiers
import UIKit

extension URL {
    static func fromGuide(guideItemID: String, language: String, shareable: Bool? = nil) -> URL {
        let baseURL = "https://celestia.mobi/resources/guide"
        var components = URLComponents(string: baseURL)!
        #if targetEnvironment(macCatalyst)
        let platform = "catalyst"
        #else
        let platform = "ios"
        #endif
        var queryItems = [
            URLQueryItem(name: "guide", value: guideItemID),
            URLQueryItem(name: "lang", value: language),
            URLQueryItem(name: "platform", value: platform),
            URLQueryItem(name: "theme", value: "dark")
        ]
        if let shareable = shareable {
            queryItems.append(URLQueryItem(name: "share", value: shareable ? "true" : "false"))
        }
        components.queryItems = queryItems
        return components.url!
    }

    static func fromAddon(addonItemID: String, language: String) -> URL {
        let baseURL = "https://celestia.mobi/resources/item"
        var components = URLComponents(string: baseURL)!
        #if targetEnvironment(macCatalyst)
        let platform = "catalyst"
        #else
        let platform = "ios"
        #endif
        components.queryItems = [
            URLQueryItem(name: "item", value: addonItemID),
            URLQueryItem(name: "lang", value: language),
            URLQueryItem(name: "platform", value: platform),
            URLQueryItem(name: "theme", value: "dark"),
            URLQueryItem(name: "titleVisibility", value: "visible"),
        ]
        return components.url!
    }
}

class MainViewController: UIViewController {
    enum LoadingStatus {
        case notLoaded
        case loading
        case loadingFailed
        case loaded
    }

    let celestiaController: CelestiaViewController
    private lazy var loadingController = LoadingViewController()

    private var status: LoadingStatus = .notLoaded
    private var retried: Bool = false

    private lazy var toolbarSlideInManager = PresentationManager(direction: UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .left : .right)
    private lazy var endSlideInManager = PresentationManager(direction: UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .left : .right, useSheetIfPossible: true)
    private lazy var bottomSlideInManager = PresentationManager(direction: UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .bottomRight : .bottomLeft)

    private lazy var core = AppCore.shared

    private var viewControllerStack: [UIViewController] = []

    #if !targetEnvironment(macCatalyst)
    private var currentExternalScreenToSwitchTo: UIScreen?
    #endif

    private var scriptOrCelURL: UniformedURL?
    private var addonToOpen: String?
    private var guideToOpen: String?

    init(initialURL: UniformedURL?, screen: UIScreen) {
        celestiaController = CelestiaViewController(screen: screen)
        super.init(nibName: nil, bundle: nil)

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

        view.backgroundColor = .darkBackground

        celestiaController.delegate = self
        install(celestiaController)

        install(loadingController)

        NotificationCenter.default.addObserver(self, selector: #selector(newURLOpened(_:)), name: newURLOpenedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newAddonOpened(_:)), name: newAddonOpenedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newGuideOpened(_:)), name: newGuideOpenedNotificationName, object: nil)
        #if !targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(self, selector: #selector(newScreenConnected(_:)), name: UIScreen.didConnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenDisconnected(_:)), name: UIScreen.didDisconnectNotification, object: nil)
        #endif
        NotificationCenter.default.addObserver(self, selector: #selector(presentHelp), name: showHelpNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showSettings), name: showPreferencesNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(requestOpenFile), name: requestOpenFileNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(requestCopy), name: requestCopyNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(requestPaste), name: requestPasteNotificationName, object: nil)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
         return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
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
        let browser: UIDocumentPickerViewController
        if #available(iOS 14, *) {
            let types = Set([UTType(filenameExtension: "cel"), UTType(filenameExtension: "celx"), UTType(exportedAs: "space.celestia.script")]).compactMap { $0 }
            browser = UIDocumentPickerViewController(forOpeningContentTypes: types)
        } else {
            let types = ["space.celestia.script", "public.flc-animation"] // .cel extension is taken by public.flc-animation
            browser = UIDocumentPickerViewController(documentTypes: types, in: .open)
        }
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

        let onboardMessageDisplayed: Bool? = UserDefaults.app[.onboardMessageDisplayed]
        if onboardMessageDisplayed == nil {
            UserDefaults.app[.onboardMessageDisplayed] = true
            presentHelp()
            cleanup()
            return
        }

        if let url = scriptOrCelURL {
            if url.url.isFileURL {
                front?.showOption(CelestiaString("Run script?", comment: "")) { [unowned self] (confirmed) in
                    guard confirmed else { return }
                    self.celestiaController.openURL(url)
                }
            } else if url.url.scheme == "cel" {
                front?.showOption(CelestiaString("Open URL?", comment: "")) { [unowned self] (confirmed) in
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
            let nav = UINavigationController(rootViewController: CommonWebViewController(url: .fromGuide(guideItemID: guide, language: locale), matchingQueryKeys: ["guide"]))
            nav.setNavigationBarHidden(true, animated: false)
            showViewController(nav, key: guide, titleVisible: false)
            cleanup()
            return
        }

        if let addon = addonToOpen {
            let requestURL = apiPrefix + "/resource/item"
            _ = RequestHandler.get(url: requestURL, parameters: ["lang": locale, "item": addon], success: { [weak self] (item: ResourceItem) in
                guard let self = self else { return }
                // Need to wrap it in a NavVC without NavBar to make sure
                // the scrolling behavior is correct on macCatalyst
                let nav = UINavigationController(rootViewController: ResourceItemViewController(item: item, needsRefetchItem: false))
                nav.setNavigationBarHidden(true, animated: false)
                self.showViewController(nav, key: addon, titleVisible: false)
            }, decoder: ResourceItem.networkResponseDecoder)
            cleanup()
            return
        }

        // Check news
        let requestURL = apiPrefix + "/resource/latest"
        _ = RequestHandler.get(url: requestURL, parameters: ["lang": locale, "type": "news"], success: { [weak self] (item: GuideItem) in
            guard let self = self else { return }
            if UserDefaults.app[.lastNewsID] == item.id { return }
            let vc = CommonWebViewController(url: .fromGuide(guideItemID: item.id, language: locale), matchingQueryKeys: ["guide"])
            vc.ackHandler = { id in
                if id == item.id {
                    UserDefaults.app[.lastNewsID] = item.id
                }
            }
            let nav = UINavigationController(rootViewController: vc)
            nav.setNavigationBarHidden(true, animated: false)
            self.showViewController(nav, key: item.id, titleVisible: false)
        }, failure: nil)
    }
}

extension MainViewController {
    @objc private func requestCopy() {
        core.run { core in
            let url = core.currentURL
            DispatchQueue.main.async {
                UIPasteboard.general.url = URL(string: url)
            }
        }
    }

    @objc private func requestPaste() {
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
            core.run { $0.go(to: url) }
        }
    }
}

extension MainViewController {
    #if !targetEnvironment(macCatalyst)
    @objc private func newScreenConnected(_ notification: Notification) {
        guard let newScreen = notification.object as? UIScreen else { return }
        // Avoid handling connecting to a new screen when we are working on a screen already
        guard currentExternalScreenToSwitchTo == nil else { return }

        currentExternalScreenToSwitchTo = newScreen
        showOption(CelestiaString("An external screen is connected, do you want to display Celestia on the external screen?", comment: "")) { [weak self] choice in
            guard choice, let self = self else { return }
            self.currentExternalScreenToSwitchTo = nil

            guard self.celestiaController.move(to: newScreen) else {
                self.showError(CelestiaString("Failed to connect to the external screen.", comment: ""))
                return
            }
        }
    }

    @objc private func screenDisconnected(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }

        if screen == currentExternalScreenToSwitchTo {
            // The screen we are asking to connect is disconnected, dismiss
            // the presented alert controller
            dismiss(animated: true, completion: nil)
            currentExternalScreenToSwitchTo = nil
            return
        }

        guard celestiaController.isMirroring else {
            // Not mirroring, ignore
            return
        }

        guard screen == celestiaController.displayScreen else {
            // Not the screen we expected
            return
        }

        guard celestiaController.moveBack(from: screen) else {
            // Unable to move back from the screen
            return
        }
    }
    #endif

    func moveDisplayBack(from window: UIWindow) {
        celestiaController.moveBack(from: window)
    }

    func moveDisplay(to window: UIWindow, screen: UIScreen) {
        celestiaController.move(to: window, screen: screen)
    }
}

extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        scriptOrCelURL = UniformedURL(url: url, securityScoped: true)
        openURLOrScriptOrGreeting()
    }
}

extension MainViewController: CelestiaControllerDelegate {
    func celestiaController(_ celestiaController: CelestiaViewController, loadingStatusUpdated status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.loadingController.update(with: status)
        }
    }

    func celestiaControllerLoadingFailedShouldRetry(_ celestiaController: CelestiaViewController) -> Bool {
        if retried { return false }
        DispatchQueue.main.async { [weak self] in
            self?.showError(CelestiaString("Error loading data, fallback to original configuration.", comment: ""))
        }
        retried = true
        saveConfigFile(nil)
        saveDataDirectory(nil)
        return true
    }

    func celestiaControllerLoadingFailed(_ celestiaController: CelestiaViewController) {
        print("loading failed")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.status = .loadingFailed
            self.loadingController.remove()
            let failure = LoadingFailureViewController()
            self.install(failure)
        }
    }

    func celestiaControllerLoadingSucceeded(_ celestiaController: CelestiaViewController) {
        print("loading success")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.status = .loaded
            self.loadingController.remove()
            #if targetEnvironment(macCatalyst)
            self.setupToolbar()
            self.setupTouchBar()
            #endif
            if #available(iOS 13.0, *) {
                UIMenuSystem.main.setNeedsRebuild()
            }
            UIApplication.shared.isIdleTimerDisabled = true

            self.openURLOrScriptOrGreeting()
        }
    }

    func celestiaController(_ celestiaController: CelestiaViewController, requestShowActionMenuWithSelection selection: Selection) {
        let actions: [[AppToolbarAction]] = AppToolbarAction.persistentAction
        let controller = ToolbarViewController(actions: actions)
        controller.selectionHandler = { [unowned self] (action) in
            guard let ac = action as? AppToolbarAction else { return }
            self.toolbarActionSelected(ac)
        }
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = toolbarSlideInManager
        presentAfterDismissCurrent(controller, animated: true)
    }

    func celestiaController(_ celestiaController: CelestiaViewController, requestShowInfoWithSelection selection: Selection) {
        guard !selection.isEmpty else { return }
        showSelectionInfo(with: selection)
    }

    func celestiaController(_ celestiaController: CelestiaViewController, requestWebInfo webURL: URL) {
        showWeb(webURL)
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
            core.receiveAsync(.home)
        case .event:
            presentEventFinder()
        case .addons:
            presentInstalledAddons()
        case .download:
            let baseURL = "https://celestia.mobi/resources/categories"
            var components = URLComponents(string: baseURL)!
            components.queryItems = [
                URLQueryItem(name: "lang", value: AppCore.language),
                URLQueryItem(name: "theme", value: "dark"),
                URLQueryItem(name: "platform", value: "ios"),
                URLQueryItem(name: "api", value: "1"),
            ]
            let url = components.url!
            let nav = UINavigationController(rootViewController: CommonWebViewController(url: url, filterURL: false))
            showViewController(nav)
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
        #if targetEnvironment(macCatalyst)
        case .mirror:
            if UIApplication.shared.connectedScenes.contains(where: { $0.delegate is DisplaySceneDelegate }) {
                return
            }
            let activity = NSUserActivity(activityType: DisplaySceneDelegate.activityType)
            UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { _ in }
        #endif
        }
    }

    private func presentShare() {
        showSelection(nil, options: [CelestiaString("Image", comment: ""), CelestiaString("URL", comment: "")], source: nil) { [weak self] index in
            guard let self = self, let index = index else { return }
            if index == 0 {
                self.shareImage()
            } else {
                self.shareURL()
            }
        }
    }

    private func shareImage() {
        core.run { [weak self] core in
            AppCore.makeRenderContextCurrent()
            core.draw()
            let path = (NSTemporaryDirectory() as NSString).appendingPathComponent("CelestiaScreenshot.png")
            if core.screenshot(to: path, type: .PNG) {
                #if targetEnvironment(macCatalyst)
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.saveFile(path)
                }
                #else
                if let data = try? Data(contentsOf: URL(fileURLWithPath: path)), let image = UIImage(data: data) {
                    try? FileManager.default.removeItem(atPath: path)
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        self.showShareSheet(for: image)
                    }
                }
                #endif
            }
        }
    }

    private func shareURL() {
        core.run { [weak self] core in
            let selection = core.simulation.selection
            let name = core.simulation.universe.name(for: selection)
            let url = core.currentURL

            DispatchQueue.main.async {
                guard let self = self else { return }
                self.requestShareURL(url, placeholder: name)
            }
        }
    }

    private func presentFavorite(_ root: FavoriteRoot) {
        let controller = FavoriteCoordinatorController(root: root, selected: { [unowned self] object in
            if let url = object as? URL {
                self.celestiaController.openURL(UniformedURL(url: url, securityScoped: false))
            } else if let destination = object as? Destination {
                self.core.run { $0.simulation.goToDestination(destination) }
            }
        }, share: { object, viewController in
            guard let node = object as? BookmarkNode, node.isLeaf else { return }
            viewController.requestShareURL(node.url, placeholder: node.name)
        })
#if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600), titleVisible: false)
#else
        showViewController(controller)
#endif
    }

    private func presentScriptToolbar() {
        presentActionToolbar(for: [CelestiaAction.playpause, .cancelScript].map { .toolbarAction($0) })
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
        presentActionToolbar(for: (layoutDirectionDependentActions + [CelestiaAction.reverse]).map { .toolbarAction($0) })
    }

    private func presentActionToolbar(for actions: [BottomControlAction]) {
        let controller = BottomControlViewController(actions: actions, finishOnSelection: false)
        controller.touchUpHandler = { [unowned self] action, inside in
            if let ac = action as? CelestiaAction {
                if inside {
                    self.core.receiveAsync(ac)
                }
            } else if let ac = action as? CelestiaContinuousAction {
                self.core.run { core in
                    core.keyUp(ac.rawValue)
                }
            }
        }
        controller.touchDownHandler = { [unowned self] action in
            if let ac = action as? CelestiaContinuousAction {
                self.core.run { core in
                    core.keyDown(ac.rawValue)
                }
            }
        }
        #if targetEnvironment(macCatalyst)
        controller.touchBarActionConversionBlock = { (identifier) in
            return CelestiaAction(identifier)
        }
        #endif
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = bottomSlideInManager
        presentAfterDismissCurrent(controller, animated: true)
    }

    private func presentCameraControl() {
        let vc = CameraControlViewController()
        let controller = UINavigationController(rootViewController: vc)
        if #available(iOS 13.0, *) {
        } else {
            controller.navigationBar.barStyle = .black
            controller.navigationBar.barTintColor = .darkBackground
            controller.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
        }
        showViewController(controller)
    }

    @objc private func presentHelp() {
        let url = URL.fromGuide(guideItemID: "823FB82E-F660-BE54-F3E4-681F5BFD365D", language: AppCore.language, shareable: false)
        let vc = FallbackWebViewController(url: url, fallbackViewControllerCreator: OnboardViewController() { [unowned self] (action) in
            switch action {
            case .tutorial(let tutorial):
                self.handleTutorialAction(tutorial)
            case .url(let url):
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })
        let nav = UINavigationController(rootViewController: vc)
        nav.setNavigationBarHidden(true, animated: false)
        showViewController(nav, titleVisible: false)
    }

    private func presentEventFinder() {
        showViewController(EventFinderCoordinatorViewController { [unowned self] eclipse in
            self.core.run { $0.simulation.goToEclipse(eclipse) }
        })
    }

    private func presentInstalledAddons() {
        let controller = ResourceViewController()
        showViewController(controller)
    }

    private func presentGoTo() {
        showViewController(GoToContainerViewController() { [weak self] location in
            self?.core.run { $0.simulation.go(to: location) }
        })
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
        presentActionToolbar(for: layoutDirectionDependentActions.map { .toolbarAction($0) } + [
            .toolbarAction(CelestiaAction.stop),
            .toolbarAction(CelestiaAction.reverseSpeed),
            .groupedActions([
                CelestiaContinuousAction.f2,
                CelestiaContinuousAction.f3,
                CelestiaContinuousAction.f4,
                CelestiaContinuousAction.f5,
                CelestiaContinuousAction.f6,
                CelestiaContinuousAction.f7,
            ])
        ])
    }

    private func showSelectionInfo(with selection: Selection) {
        let viewController = createSelectionInfoViewController(with: selection, isEmbeddedInNavigation: false)
        showViewController(viewController, titleVisible: false)
    }

    private func createSelectionInfoViewController(with selection: Selection, isEmbeddedInNavigation: Bool) -> InfoViewController {
        let controller = InfoViewController(info: selection, isEmbeddedInNavigationController: isEmbeddedInNavigation)
        controller.selectionHandler = { [unowned self] (viewController, action, sender) in
            switch action {
            case .select:
                self.core.run { $0.simulation.selection = selection }
            case .wrapped(let cac):
                self.core.selectAndReceiveAsync(selection, action: cac)
            case .web(let url):
                self.showWeb(url)
            case .subsystem:
                self.showSubsystem(with: selection)
            case .alternateSurfaces:
                self.showAlternateSurfaces(of: selection, with: sender, viewController: viewController)
            case .mark:
                self.showMarkMenu(with: selection, with: sender, viewController: viewController)
            }
        }
        controller.menuProvider = { [unowned self] action in
            let children: [UIAction]
            switch action {
            case .mark:
                let options = (0...MarkerRepresentation.crosshair.rawValue).map{ MarkerRepresentation(rawValue: $0)?.localizedTitle ?? "" } + [CelestiaString("Unmark", comment: "")]
                children = options.enumerated().map { index, option in
                    return UIAction(title: option) { _ in
                        if let marker = MarkerRepresentation(rawValue: UInt(index)) {
                            self.core.markAsync(selection, markerType: marker)
                        } else {
                            self.core.run { $0.simulation.universe.unmark(selection) }
                        }
                    }
                }
            case .alternateSurfaces:
                let alternativeSurfaces = selection.body?.alternateSurfaceNames ?? []
                if alternativeSurfaces.isEmpty {
                    children = []
                } else {
                    children = ([CelestiaString("Default", comment: "")] + alternativeSurfaces).enumerated().map { index, option in
                        return UIAction(title: option) { _ in
                            if index == 0 {
                                self.core.run { $0.simulation.activeObserver.displayedSurface = "" }
                                return
                            }
                            self.core.run { $0.simulation.activeObserver.displayedSurface = alternativeSurfaces[index - 1] }
                        }
                    }
                }
            default:
                children = []
            }
            return children.isEmpty ? nil : UIMenu(children: children)
        }
        return controller
    }

    private func showMarkMenu(with selection: Selection, with sender: UIView, viewController: UIViewController) {
        let options = (0...MarkerRepresentation.crosshair.rawValue).map{ MarkerRepresentation(rawValue: $0)?.localizedTitle ?? "" } + [CelestiaString("Unmark", comment: "")]
        viewController.showSelection(CelestiaString("Mark", comment: ""), options: options, source: .view(view: sender, sourceRect: nil)) { [weak self] index in
            guard let self = self, let index = index else { return }
            if let marker = MarkerRepresentation(rawValue: UInt(index)) {
                self.core.markAsync(selection, markerType: marker)
            } else {
                self.core.run { $0.simulation.universe.unmark(selection) }
            }
        }
    }

    private func showAlternateSurfaces(of selection: Selection, with sender: UIView, viewController: UIViewController) {
        guard let alternativeSurfaces = selection.body?.alternateSurfaceNames, alternativeSurfaces.count > 0 else { return }
        viewController.showSelection(CelestiaString("Alternate Surfaces", comment: ""), options: [CelestiaString("Default", comment: "")] + alternativeSurfaces, source: .view(view: sender, sourceRect: nil)) { [weak self] index in
            guard let self = self, let index = index else { return }

            if index == 0 {
                self.core.run { $0.simulation.activeObserver.displayedSurface = "" }
                return
            }
            self.core.run { $0.simulation.activeObserver.displayedSurface = alternativeSurfaces[index - 1] }
        }
    }

    private func showWeb(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func showSubsystem(with selection: Selection) {
        guard let entry = selection.object else { return }
        let browserItem = BrowserItem(name: core.simulation.universe.name(for: selection), alternativeName: nil, catEntry: entry, provider: core.simulation.universe)
        let controller = SubsystemBrowserCoordinatorViewController(item: browserItem) { [unowned self] (selection) -> UIViewController in
            return self.createSelectionInfoViewController(with: selection, isEmbeddedInNavigation: true)
        }
        showViewController(controller)
    }

    @objc private func showSettings() {
        let controller = SettingsCoordinatorController(actionHandler: { [weak self] settingsAction in
            switch settingsAction {
            case .refreshFrameRate(let newFrameRate):
                UserDefaults.app[.frameRate] = newFrameRate
                self?.celestiaController.updateFrameRate(newFrameRate)
            }
        }, screenProvider: { [unowned self] in
            return self.celestiaController.displayScreen
        })
        #if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600), titleVisible: false)
        #else
        showViewController(controller)
        #endif
    }

    private func showSearch() {
        let controller = SearchCoordinatorController { [unowned self] info, isEmbeddedInNavigation in
            return self.createSelectionInfoViewController(with: info, isEmbeddedInNavigation: isEmbeddedInNavigation)
        }
        #if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600), titleVisible: false)
        #else
        showViewController(controller)
        #endif
    }

    private func showBrowser() {
        let controller = BrowserContainerViewController(selected: { [unowned self] (info) in
            return self.createSelectionInfoViewController(with: info, isEmbeddedInNavigation: true)
        })
        #if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 500, height: 600), titleVisible: false)
        #else
        showViewController(controller)
        #endif
    }

    private func showViewController(_ viewController: UIViewController,
                                    key: String? = nil,
                                    iOSPreferredSize: CGSize = CGSize(width: 320, height: 320),
                                    macOSPreferredSize: CGSize = CGSize(width: 400, height: 500),
                                    titleVisible: Bool = true) {
        #if targetEnvironment(macCatalyst)
        PanelSceneDelegate.present(viewController, key: key, preferredSize: macOSPreferredSize, titleVisible: titleVisible)
        #else
        viewController.preferredContentSize = iOSPreferredSize
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = endSlideInManager

        presentAfterDismissCurrent(viewController, animated: true)
        #endif
    }
}

extension MainViewController {
    private func handleTutorialAction(_ action: TutorialAction) {
        dismiss(animated: true, completion: nil)
        switch action {
        case .runDemo:
            core.receiveAsync(.runDemo)
        }
    }
}

extension UIViewController {
    func requestShareURL(_ url: String, placeholder: String) {
        let showShareFail: (String?) -> Void = { [unowned self] message in
            self.showError(CelestiaString("Cannot share URL", comment: ""), detail: message)
        }
        guard let url = URL(string: url) else {
            showShareFail(nil)
            return
        }

        class CelestiaURLObject: NSObject, UIActivityItemSource {
            func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
                return url
            }

            func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
                return url
            }

            func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
                let metadata = LPLinkMetadata()
                metadata.url = url
                metadata.title = title
                metadata.originalURL = url
                return metadata
            }

            let title: String
            let url: URL

            init(title: String, url: URL) {
                self.title = title
                self.url = url
                super.init()
            }
        }

        showShareSheet(for: CelestiaURLObject(title: placeholder, url: url))
    }

    func showShareSheet(for item: Any) {
        let activityController = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        callAfterDismissCurrent(animated: true) { [weak self] in
            guard let self = self else { return }
            self.present(activityController, source: nil)
        }
    }

    func callAfterDismissCurrent(animated: Bool, block: @escaping () -> Void) {
        if presentedViewController == nil || presentedViewController?.isBeingDismissed == true {
            block()
        } else {
            dismiss(animated: animated) {
                block()
            }
        }
    }

    func presentAfterDismissCurrent(_ viewController: UIViewController, animated: Bool) {
        callAfterDismissCurrent(animated: animated) { [weak self] in
            self?.present(viewController, animated: animated)
        }
    }
}

#if targetEnvironment(macCatalyst)
extension MainViewController {
    private func saveFile(_ path: String) {
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            picker = UIDocumentPickerViewController(forExporting: [URL(fileURLWithPath: path)], asCopy: false)
        } else {
            picker = UIDocumentPickerViewController(url: URL(fileURLWithPath: path), in: .moveToService)
        }
        picker.shouldShowFileExtensions = true
        picker.allowsMultipleSelection = false
        presentAfterDismissCurrent(picker, animated: true)
    }
}
#endif

#if targetEnvironment(macCatalyst)
extension MainViewController: NSToolbarDelegate {
    private var undoOrRedoGroupItemIdentifier: NSToolbarItem.Identifier {
        return NSToolbarItem.Identifier("undoOrRedoGroup")
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == undoOrRedoGroupItemIdentifier {
            let toolbarItemGroup = NSToolbarItemGroup(itemIdentifier: itemIdentifier, images: [UIImage(systemName: "chevron.left")!, UIImage(systemName: "chevron.right")!], selectionMode: .momentary, labels: [CelestiaString("Backward", comment: ""), CelestiaString("Forward", comment: "")], target: self, action: #selector(undoOrRedo(_:)))
            return toolbarItemGroup
        }

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
        return
            [undoOrRedoGroupItemIdentifier] +
            [AppToolbarAction.browse, .favorite, .home, .paperplane].map { NSToolbarItem.Identifier($0.rawValue) } +
            [.flexibleSpace] +
            [AppToolbarAction.share, .mirror, .search].map { NSToolbarItem.Identifier($0.rawValue) }
    }

    private func availableIdentifiers() -> [NSToolbarItem.Identifier] {
        var actions = AppToolbarAction.persistentAction.reduce([AppToolbarAction](), { $0 + $1 })
        actions.append(.mirror)
        return actions.map { NSToolbarItem.Identifier(rawValue: $0.rawValue) } + [.flexibleSpace, .space] + [undoOrRedoGroupItemIdentifier]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return defaultToolbarIdentifiers()
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return availableIdentifiers()
    }

    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: Bundle.app.bundleIdentifier!)
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        toolbar.delegate = self
        view.window?.windowScene?.titlebar?.titleVisibility = .hidden
        view.window?.windowScene?.titlebar?.toolbar = toolbar
    }

    @objc private func toolbarButtonItemClicked(_ sender: NSToolbarItem) {
        guard let action = AppToolbarAction(rawValue: sender.itemIdentifier.rawValue) else { return }
        toolbarActionSelected(action)
    }

    @objc private func undoOrRedo(_ sender: NSToolbarItemGroup) {
        if sender.selectedIndex == 0 {
            core.run { $0.back() }
        } else {
            core.run { $0.forward() }
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
    var image: UIImage? {
        switch self {
        case .playpause:
            return UIImage(systemName: "playpause.fill")
        case .faster:
            return UIImage(systemName: "forward.fill")
        case .slower:
            return UIImage(systemName: "backward.fill")
        case .reverse, .reverseSpeed:
            return UIImage(systemName: "repeat")?.withConfiguration(UIImage.SymbolConfiguration(weight: .black))
        case .cancelScript, .stop:
            return UIImage(systemName: "stop.fill")
        default:
            return nil
        }
    }
}

extension CelestiaContinuousAction: ToolbarAction {
    var image: UIImage? {
        switch self {
        case .travelFaster:
            return UIImage(systemName: "forward.fill")
        case .travelSlower:
            return UIImage(systemName: "backward.fill")
        default:
            return nil
        }
    }

    var title: String? {
        switch self {
        case .f2:
            return CelestiaString("1 km/s", comment: "")
        case .f3:
            return CelestiaString("1000 km/s", comment: "")
        case .f4:
            return CelestiaString("c (lightspeed)", comment: "")
        case .f5:
            return CelestiaString("10c", comment: "")
        case .f6:
            return CelestiaString("1 AU/s", comment: "")
        case .f7:
            return CelestiaString("1 ly/s", comment: "")
        default:
            return nil
        }
    }
}

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

extension MarkerRepresentation {
    var localizedTitle: String {
        return CelestiaString(unlocalizedTitle, comment: "")
    }

    private var unlocalizedTitle: String {
        switch self {
        case .circle:
            return "Circle"
        case .triangle:
            return "Triangle"
        case .plus:
            return "Plus"
        case .X:
            return "X"
        case .crosshair:
            return "Crosshair"
        case .diamond:
            return "Diamond"
        case .disk:
            return "Disk"
        case .filledSquare:
            return "Filled Square"
        case .leftArrow:
            return "Left Arrow"
        case .upArrow:
            return "Up Arrow"
        case .rightArrow:
            return "Right Arrow"
        case .downArrow:
            return "Down Arrow"
        case .square:
            return "Square"
        @unknown default:
            return "Unknown"
        }
    }
}
