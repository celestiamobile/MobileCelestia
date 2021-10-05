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

import UIKit

import CelestiaCore

import UniformTypeIdentifiers

class MainViewController: UIViewController {
    enum LoadingStatus {
        case notLoaded
        case loading
        case loadingFailed
        case loaded
    }

    private lazy var celestiaController = CelestiaViewController()
    private lazy var loadingController = LoadingViewController()

    private var status: LoadingStatus = .notLoaded
    private var retried: Bool = false

    private lazy var toolbarSlideInManager = PresentationManager(direction: UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .left : .right)
    private lazy var endSlideInManager = PresentationManager(direction: UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .left : .right, useSheetIfPossible: true)
    private lazy var bottomSlideInManager = PresentationManager(direction: UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .bottomRight : .bottomLeft)

    private lazy var core = CelestiaAppCore.shared

    private var viewControllerStack: [UIViewController] = []

    #if !targetEnvironment(macCatalyst)
    private var currentExternalScreenToSwitchTo: UIScreen?
    private var currentDisplayingScreen: UIScreen = .main
    #endif

    private var urlToRun: UniformedURL?

    init(initialURL: UniformedURL?) {
        self.urlToRun = initialURL
        super.init(nibName: nil, bundle: nil)
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
        urlToRun = url
        guard status == .loaded else { return }
        checkNeedOpeningURL()
    }

    private func checkNeedOpeningURL() {
        guard let url = urlToRun else { return }

        urlToRun = nil

        let title = url.url.isFileURL ? CelestiaString("Run script?", comment: "") : CelestiaString("Open URL?", comment: "")
        front?.showOption(title) { [unowned self] (confirmed) in
            guard confirmed else { return }
            self.celestiaController.openURL(url)
        }
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
        if pasteboard.hasURLs, let url = pasteboard.url {
            core.run { $0.go(to: url.absoluteString) }
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

            guard self.celestiaController.moveToNewScreen(newScreen) else {
                self.showError(CelestiaString("Failed to connect to the external screen.", comment: ""))
                return
            }
            self.currentDisplayingScreen = newScreen
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

        celestiaController.moveBack(from: screen)
        currentDisplayingScreen = .main
    }
    #endif
}

extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        urlToRun = UniformedURL(url: url, securityScoped: true)
        checkNeedOpeningURL()
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
            UIApplication.shared.isIdleTimerDisabled = true
            self.showOnboardMessageIfNeeded()
            // we can't present two vcs together, so we delay the action
            DispatchQueue.main.asyncAfter(deadline: .now() + 1)  {
                self.checkNeedOpeningURL()
            }
        }
    }

    func celestiaController(_ celestiaController: CelestiaViewController, requestShowActionMenuWithSelection selection: CelestiaSelection) {
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

    func celestiaController(_ celestiaController: CelestiaViewController, requestShowInfoWithSelection selection: CelestiaSelection) {
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
            presentPlugins()
        case .paperplane:
            presentGoTo()
        case .speedometer:
            presentSpeedControl()
        }
    }

    private func presentShare() {
        let centerView = UIView()
        centerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(centerView)
        NSLayoutConstraint.activate([
            centerView.widthAnchor.constraint(equalToConstant: 1),
            centerView.heightAnchor.constraint(equalToConstant: 1),
            centerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        showSelection(nil, options: [CelestiaString("Image", comment: ""), CelestiaString("URL", comment: "")], sourceView: centerView, sourceRect: CGRect(x: 0, y: 0, width: 1, height: 1)) { [weak self] index in
            centerView.removeFromSuperview()
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
            CelestiaAppCore.makeRenderContextCurrent()
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
                urlToRun = UniformedURL(url: url, securityScoped: false)
                self.checkNeedOpeningURL()
            } else if let destination = object as? CelestiaDestination {
                self.core.run { $0.simulation.goToDestination(destination) }
            }
        }, share: { object, viewController in
            guard let node = object as? BookmarkNode, node.isLeaf else { return }
            viewController.requestShareURL(node.url, placeholder: node.name)
        })
        #if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600))
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
        showViewController(OnboardViewController() { [unowned self] (action) in
            switch action {
            case .tutorial(let tutorial):
                self.handleTutorialAction(tutorial)
            case .url(let url):
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })
    }

    private func presentEventFinder() {
        showViewController(EventFinderCoordinatorViewController { [unowned self] eclipse in
            self.core.run { $0.simulation.goToEclipse(eclipse) }
        })
    }

    private func presentPlugins() {
        let controller = ResourceViewController()
        #if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600))
        #else
        showViewController(controller)
        #endif
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

    private func showSelectionInfo(with selection: CelestiaSelection) {
        showViewController(createSelectionInfoViewController(with: selection, isEmbeddedInNavigation: false))
    }

    private func createSelectionInfoViewController(with selection: CelestiaSelection, isEmbeddedInNavigation: Bool) -> InfoViewController {
        let controller = InfoViewController(info: selection, isEmbeddedInNavigationController: isEmbeddedInNavigation)
        controller.selectionHandler = { [unowned self] (action, sender) in
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
                self.showAlternateSurfaces(of: selection, with: sender)
            case .mark:
                self.showMarkMenu(with: selection, with: sender)
            }
        }
        return controller
    }

    private func showMarkMenu(with selection: CelestiaSelection, with sender: UIView) {
        let options = (0...CelestiaMarkerRepresentation.crosshair.rawValue).map{ CelestiaMarkerRepresentation(rawValue: $0)?.localizedTitle ?? "" } + [CelestiaString("Unmark", comment: "")]
        front?.showSelection(CelestiaString("Mark", comment: ""), options: options, sourceView: sender, sourceRect: sender.bounds) { [weak self] index in
            guard let self = self, let index = index else { return }
            if let marker = CelestiaMarkerRepresentation(rawValue: UInt(index)) {
                self.core.markAsync(selection, markerType: marker)
            } else {
                self.core.run { $0.simulation.universe.unmark(selection) }
            }
        }
    }

    private func showAlternateSurfaces(of selection: CelestiaSelection, with sender: UIView) {
        guard let alternativeSurfaces = selection.body?.alternateSurfaceNames, alternativeSurfaces.count > 0 else { return }
        front?.showSelection(CelestiaString("Alternate Surfaces", comment: ""), options: [CelestiaString("Default", comment: "")] + alternativeSurfaces, sourceView: sender, sourceRect: sender.bounds) { [weak self] index in
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

    private func showSubsystem(with selection: CelestiaSelection) {
        guard let entry = selection.object else { return }
        let browserItem = CelestiaBrowserItem(name: core.simulation.universe.name(for: selection), alternativeName: nil, catEntry: entry, provider: core.simulation.universe)
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
        }, screenProvider: { [weak self] in
            #if targetEnvironment(macCatalyst)
            return .main
            #else
            return self?.currentDisplayingScreen ?? .main
            #endif
        })
        #if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600))
        #else
        showViewController(controller)
        #endif
    }

    private func showSearch() {
        let controller = SearchCoordinatorController { [unowned self] (info) in
            return self.createSelectionInfoViewController(with: info, isEmbeddedInNavigation: true)
        }
        #if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600))
        #else
        showViewController(controller)
        #endif
    }

    private func showBrowser() {
        let controller = BrowserContainerViewController(selected: { [unowned self] (info) in
            return self.createSelectionInfoViewController(with: info, isEmbeddedInNavigation: true)
        })
        #if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600))
        #else
        showViewController(controller)
        #endif
    }

    private func showViewController(_ viewController: UIViewController,
                                    iOSPreferredSize: CGSize = CGSize(width: 320, height: 320),
                                    macOSPreferredSize: CGSize = CGSize(width: 400, height: 500)) {
        #if targetEnvironment(macCatalyst)
        PanelSceneDelegate.present(viewController, preferredSize: macOSPreferredSize)
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
        case .showDestinations:
            presentFavorite(.destinations)
        }
    }

    private func showOnboardMessageIfNeeded() {
        let onboardMessageDisplayed: Bool? = UserDefaults.app[.onboardMessageDisplayed]
        if onboardMessageDisplayed == nil {
            UserDefaults.app[.onboardMessageDisplayed] = true
            presentHelp()
        }
    }
}

extension UIViewController {
    func requestShareURL(_ url: String, placeholder: String) {
        showTextInput(
            CelestiaString("Share", comment: ""),
            message: CelestiaString("Please enter a description of the content.", comment: ""),
            text: placeholder) { [unowned self] description in
            guard let title = description else { return }
            self.submitURL(url, title: title)
        }
    }

    func submitURL(_ url: String, title: String) {
        let requestURL = apiPrefix + "/create"

        struct URLCreationResponse: Decodable {
            let publicURL: String
        }

        let showShareFail: () -> Void = { [unowned self] in
            self.showError(CelestiaString("Cannot share URL", comment: ""))
        }

        guard let data = url.data(using: .utf8) else {
            showShareFail()
            return
        }

        let alert = showLoading(CelestiaString("Generating sharing link…", comment: ""))
        _ = RequestHandler.post(url: requestURL, parameters: [
            "title" : title,
            "url" : data.base64EncodedURLString(),
            "version" : Bundle.app.infoDictionary!["CFBundleVersion"] as! String
        ], success: { [unowned self] (result: URLCreationResponse) in
            alert.dismiss(animated: true) {
                guard let url = URL(string: result.publicURL) else {
                    showShareFail()
                    return
                }
                self.showShareSheet(for: url)
            }
        }, failure: { _ in
            alert.dismiss(animated: true) {
                showShareFail()
            }
        })
    }

    func showShareSheet(for url: URL) {
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        configurePopover(for: activityController)
        presentAfterDismissCurrent(activityController, animated: true)
    }

    func configurePopover(for viewController: UIViewController) {
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.sourceView = view
        viewController.popoverPresentationController?.sourceRect = CGRect(x: view.frame.midX, y: view.frame.midY, width: 0, height: 0)
        viewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        viewController.preferredContentSize = CGSize(width: 400, height: 500)
    }

    func presentAfterDismissCurrent(_ viewController: UIViewController, animated: Bool) {
        if presentedViewController == nil || presentedViewController?.isBeingDismissed == true {
            present(viewController, animated: animated)
        } else {
            dismiss(animated: animated) { [weak self] in
                self?.present(viewController, animated: animated)
            }
        }
    }
}

extension MainViewController {
    #if targetEnvironment(macCatalyst)
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
    #else
    private func showShareSheet(for image: UIImage) {
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        configurePopover(for: activityController)
        presentAfterDismissCurrent(activityController, animated: true)
    }
    #endif
}

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
            [AppToolbarAction.share, .search].map { NSToolbarItem.Identifier($0.rawValue) }
    }

    private func availableIdentifiers() -> [NSToolbarItem.Identifier] {
        return AppToolbarAction.persistentAction.reduce([AppToolbarAction](), { $0 + $1 }).map { NSToolbarItem.Identifier(rawValue: $0.rawValue) } + [.flexibleSpace, .space] + [undoOrRedoGroupItemIdentifier]
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
        switch self {
        case .search:
            return UIImage(systemName: "magnifyingglass")
        case .share:
            return UIImage(systemName: "square.and.arrow.up")
        case .setting:
            return UIImage(systemName: "gear")
        case .browse:
            return UIImage(systemName: "globe")
        case .favorite:
            return UIImage(systemName: "star.circle")
        case .camera:
            return UIImage(systemName: "video")
        case .time:
            return UIImage(systemName: "clock")
        case .script:
            return UIImage(systemName: "doc")
        case .help:
            return UIImage(systemName: "questionmark.circle")
        case .addons:
            return UIImage(systemName: "folder")
        case .home:
            return UIImage(systemName: "house")
        case .event:
            return UIImage(systemName: "calendar")
        case .paperplane:
            return UIImage(systemName: "paperplane")
        case .speedometer:
            return UIImage(systemName: "speedometer")
        }
    }
}
#endif

extension CelestiaAction: ToolbarAction {
    var image: UIImage? {
        switch self {
        case .playpause:
            return #imageLiteral(resourceName: "time_playpause")
        case .faster:
            return #imageLiteral(resourceName: "time_faster")
        case .slower:
            return #imageLiteral(resourceName: "time_slower")
        case .reverse, .reverseSpeed:
            return #imageLiteral(resourceName: "time_reverse")
        case .cancelScript, .stop:
            return #imageLiteral(resourceName: "time_stop")
        default:
            return nil
        }
    }
}

extension CelestiaContinuousAction: ToolbarAction {
    var image: UIImage? {
        switch self {
        case .travelFaster:
            return #imageLiteral(resourceName: "time_faster")
        case .travelSlower:
            return #imageLiteral(resourceName: "time_slower")
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
        switch self {
        case .playpause:
            return UIImage(systemName: "playpause.fill")
        case .faster:
            return UIImage(systemName: "forward.fill")
        case .slower:
            return UIImage(systemName: "backward.fill")
        case .reverse, .reverseSpeed:
            return UIImage(systemName: "repeat")
        case .cancelScript, .stop:
            return UIImage(systemName: "stop.fill")
        default:
            return nil
        }
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

extension CelestiaMarkerRepresentation {
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
