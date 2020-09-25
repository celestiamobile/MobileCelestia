//
// MainViewControler.swift
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

#if !targetEnvironment(macCatalyst)
import SafariServices
#endif

private let userInitiatedDismissalFlag = 1

class MainViewControler: UIViewController {
    enum LoadingStatus {
        case notLoaded
        case loading
        case loadingFailed
        case loaded
    }

    private lazy var celestiaController = CelestiaViewController()

    private var status: LoadingStatus = .notLoaded

    private lazy var toolbarSlideInManager = SlideInPresentationManager(direction: UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .left : .right)
    private lazy var endSlideInManager = SlideInPresentationManager(direction: UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .left : .right, usesFormSheetForRegular: true)
    private lazy var bottomSlideInManager = SlideInPresentationManager(direction: UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute) == .rightToLeft ? .bottomRight : .bottomLeft)

    private lazy var core = CelestiaAppCore.shared

    private var viewControllerStack: [UIViewController] = []

    private var currentExternalScreen: UIScreen?

    private var urlToRun: URL?

    init(initialURL: URL?) {
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

        install(celestiaController)
        celestiaController.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(newURLOpened(_:)), name: newURLOpenedNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newScreenConnected(_:)), name: UIScreen.didConnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenDisconnected(_:)), name: UIScreen.didDisconnectNotification, object: nil)
        #if targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(self, selector: #selector(presentHelp), name: showHelpNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(requestOpenFile), name: requestOpenFileNotificationName, object: nil)
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard status == .notLoaded else { return }

        status = .loading

        var retried = false

        let loadingController = LoadingViewController()
        install(loadingController)

        celestiaController.load(statusUpdater: { (status) in
            loadingController.update(with: status)
        }, errorHandler: { [unowned self] in
            if retried { return false }
            DispatchQueue.main.async { self.showError(CelestiaString("Error loading data, fallback to original configuration.", comment: "")) }
            retried = true
            saveConfigFile(nil)
            saveDataDirectory(nil)
            return true
        }, completionHandler: { [unowned self] (result) in
            loadingController.remove()

            switch result {
            case .success():
                print("loading success")
                self.status = .loaded
                #if targetEnvironment(macCatalyst)
                self.setupToolbar()
                self.setupTouchBar()
                UIMenuSystem.main.setNeedsRebuild()
                #endif
                UIApplication.shared.isIdleTimerDisabled = true
                self.showOnboardMessageIfNeeded()
                // we can't present two vcs together, so we delay the action
                DispatchQueue.main.asyncAfter(deadline: .now() + 1)  {
                    self.checkNeedOpeningURL()
                }
            case .failure(_):
                print("loading failed")
                self.status = .loadingFailed
                let failure = LoadingFailureViewController()
                self.install(failure)
            }
        })
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
         return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension MainViewControler {
    #if targetEnvironment(macCatalyst)
    @objc private func requestOpenFile() {
        let types = ["space.celestia.script", "public.flc-animation"]
        let browser = UIDocumentPickerViewController(documentTypes: types, in: .open)
        browser.allowsMultipleSelection = false
        browser.delegate = self
        present(browser, animated: true, completion: nil)
    }
    #endif

    @objc private func newURLOpened(_ notification: Notification) {
        guard let url = notification.userInfo?[newURLOpenedNotificationURLKey] as? URL else { return }
        urlToRun = url
        guard status == .loaded else { return }
        checkNeedOpeningURL()
    }

    private func checkNeedOpeningURL(_ external: Bool = true, _ dismissCurrent: Bool = true) {
        guard let url = urlToRun else { return }
        urlToRun = nil

        if dismissCurrent {
            addToBackStack()
        }
        let title = url.isFileURL ? CelestiaString("Run script?", comment: "") : CelestiaString("Open URL?", comment: "")
        front?.showOption(title) { [unowned self] (confirmed) in
            if dismissCurrent {
                self.popLastAndShow()
            }

            guard confirmed else { return }
            self.celestiaController.openURL(url, external: external)
        }
    }
}

extension MainViewControler {
    @objc private func newScreenConnected(_ notification: Notification) {
        guard let newScreen = notification.object as? UIScreen else { return }
        // Avoid handling connecting to a new screen when we are working on a screen already
        guard currentExternalScreen == nil else { return }

        currentExternalScreen = newScreen
        showOption(CelestiaString("An external screen is connected, do you want to display Celestia on the external screen?", comment: "")) { [weak self] choice in
            guard choice, let self = self else { return }
            self.currentExternalScreen = nil

            guard self.celestiaController.moveToNewScreen(newScreen) else {
                self.showError(CelestiaString("Failed to connect to the external screen.", comment: ""))
                return
            }
        }
    }

    @objc private func screenDisconnected(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }

        if screen == currentExternalScreen {
            // The screen we are asking to connect is disconnected, dismiss
            // the presented alert controller
            dismiss(animated: true, completion: nil)
            currentExternalScreen = nil
            return
        }

        celestiaController.moveBack(from: screen)
    }
}

#if targetEnvironment(macCatalyst)
extension MainViewControler: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        urlToRun = url
        checkNeedOpeningURL()
    }
}
#endif

extension MainViewControler: CelestiaControllerDelegate {
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
            presentShare(selection: core.simulation.selection)
        case .favorite:
            presentFavorite()
        case .help:
            presentHelp()
        case .home:
            core.receive(.home)
        case .event:
            presentEventFinder()
        case .addons:
            presentPlugins()
        }
    }

    private func presentShare(selection: CelestiaSelection) {
        let name = core.simulation.universe.name(for: selection)
        let url = core.currentURL
        showTextInput(CelestiaString("Share", comment: ""),
                      message: CelestiaString("Please enter a description of the content.", comment: ""),
                      text: name) { (description) in
                        guard let title = description else { return }
                        self.submitURL(url, title: title)
        }
    }


    private func presentFavorite() {
        let controller = FavoriteCoordinatorController { [unowned self] (url) in
            urlToRun = url
            self.checkNeedOpeningURL(false, false)
        }
        showViewController(controller)
    }

    private func presentScriptToolbar() {
        presentActionToolbar(for: [.playpause, .cancelScript])
    }

    private func presentTimeToolbar() {
        presentActionToolbar(for: [.slower, .playpause, .faster, .reverse])
    }

    private func presentActionToolbar(for actions: [CelestiaAction]) {
        let controller = BottomControlViewController(actions: actions, finishOnSelection: false)
        controller.selectionHandler = { [unowned self] (action) in
            guard let ac = action as? CelestiaAction else { return }
            self.core.receive(ac)
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
        controller.navigationBar.barStyle = .black
        controller.navigationBar.barTintColor = .black
        controller.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
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
            self.core.simulation.goToEclipse(eclipse)
        })
    }

    private func presentPlugins() {
        showViewController(ResourceViewController())
    }

    private func showSelectionInfo(with selection: CelestiaSelection) {
        let controller = InfoViewController(info: selection)
        controller.dismissDelegate = self
        controller.selectionHandler = { [unowned self] (action, sender) in
            switch action {
            case .select:
                self.clearBackStack()
                self.core.simulation.selection = selection
            case .wrapped(let cac):
                self.clearBackStack()
                self.core.simulation.selection = selection
                self.core.receive(cac)
            case .web(let url):
                self.addToBackStack()
                self.showWeb(url)
            case .subsystem:
                self.addToBackStack()
                self.showSubsystem(with: selection)
            case .alternateSurfaces:
                self.showAlternateSurfaces(of: selection, with: sender)
            case .mark:
                self.showMarkMenu(with: selection, with: sender)
            }
        }
        showViewController(controller)
    }

    private func showMarkMenu(with selection: CelestiaSelection, with sender: UIView) {
        let options = (0...CelestiaMarkerRepresentation.crosshair.rawValue).map{ CelestiaMarkerRepresentation(rawValue: $0)?.localizedTitle ?? "" } + [CelestiaString("Unmark", comment: "")]
        front?.showSelection(CelestiaString("Mark", comment: ""), options: options, sourceView: sender, sourceRect: sender.bounds) { [weak self] index in
            guard let self = self else { return }
            if let marker = CelestiaMarkerRepresentation(rawValue: UInt(index)) {
                self.core.simulation.universe.mark(selection, with: marker)
                self.core.showMarkers = true
            } else {
                self.core.simulation.universe.unmark(selection)
            }
        }
    }

    private func showAlternateSurfaces(of selection: CelestiaSelection, with sender: UIView) {
        guard let alternativeSurfaces = selection.body?.alternateSurfaceNames, alternativeSurfaces.count > 0 else { return }
        front?.showSelection(CelestiaString("Alternate Surfaces", comment: ""), options: [CelestiaString("Default", comment: "")] + alternativeSurfaces, sourceView: sender, sourceRect: sender.bounds) { [weak self] index in
            guard let self = self else { return }

            if index == 0 {
                self.core.simulation.activeObserver.displayedSurface = ""
                return
            }
            self.core.simulation.activeObserver.displayedSurface = alternativeSurfaces[index - 1]
        }
    }

    private func showWeb(_ url: URL) {
        #if targetEnvironment(macCatalyst)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        #else
        let sf = SFSafariViewController(url: url)
        sf.dismissDelegate = self
        showViewController(sf)
        #endif
    }

    private func showSubsystem(with selection: CelestiaSelection) {
        guard let entry = selection.object else { return }
        let browserItem = CelestiaBrowserItem(name: core.simulation.universe.name(for: selection), alternativeName: nil, catEntry: entry, provider: core.simulation.universe)
        let controller = SubsystemBrowserCoordinatorViewController(item: browserItem) { [unowned self] (selection) in
            self.addToBackStack()
            self.showSelectionInfo(with: selection)
        }
        controller.dismissDelegate = self
        showViewController(controller)
    }

    private func showSettings() {
        let controller = SettingsCoordinatorController() { (_) in
        }
        showViewController(controller)
    }

    private func showSearch() {
        let controller = SearchCoordinatorController { [unowned self] (info) in
            self.addToBackStack()
            self.showSelectionInfo(with: info)
        }
        showViewController(controller)
    }

    private func showBrowser() {
        let controller = BrowserContainerViewController(selected: { [unowned self] (info) in
            self.addToBackStack()
            self.showSelectionInfo(with: info)
        })
        #if targetEnvironment(macCatalyst)
        showViewController(controller, macOSPreferredSize: CGSize(width: 700, height: 600))
        #else
        showViewController(controller)
        #endif
    }

    private func showViewController(_ viewController: UIViewController,
                                    iOSPreferredSize: CGSize = CGSize(width: 300, height: 300),
                                    macOSPreferredSize: CGSize = CGSize(width: 400, height: 500),
                                    formSheetPreferredContentSize: CGSize = CGSize(width: 400, height: 500)) {
        #if targetEnvironment(macCatalyst)
        PanelSceneDelegate.present(viewController, preferredSize: macOSPreferredSize)
        #else
        viewController.customFlag &= ~userInitiatedDismissalFlag

        viewController.regularPreferredContentSize = iOSPreferredSize
        viewController.formSheetPreferredContentSize = formSheetPreferredContentSize
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = endSlideInManager

        presentAfterDismissCurrent(viewController, animated: true)
        #endif
    }

    private func configurePopover(for viewController: UIViewController) {
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.sourceView = view
        viewController.popoverPresentationController?.sourceRect = CGRect(x: view.frame.midX, y: view.frame.midY, width: 0, height: 0)
        viewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        viewController.preferredContentSize = CGSize(width: 400, height: 500)
    }

    private func presentAfterDismissCurrent(_ viewController: UIViewController, animated: Bool) {
        if presentedViewController == nil || presentedViewController?.isBeingDismissed == true {
            present(viewController, animated: animated)
        } else {
            dismiss(animated: animated) { [weak self] in
                self?.present(viewController, animated: animated)
            }
        }
    }
}

extension MainViewControler {
    private func handleTutorialAction(_ action: TutorialAction) {
        dismiss(animated: true, completion: nil)
        switch action {
        case .runDemo:
            core.receive(.runDemo)
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

extension MainViewControler {
    private func submitURL(_ url: String, title: String) {
        let requestURL = apiPrefix + "/create"

        struct URLCreationResponse: Decodable {
            let publicURL: String
        }

        let showUnknownError: () -> Void = { [unowned self] in
            self.showError(CelestiaString("Unknown error", comment: ""))
        }

        guard let data = url.data(using: .utf8) else {
            showUnknownError()
            return
        }

        let alert = showLoading(CelestiaString("Generating sharing link…", comment: ""))
        _ = RequestHandler.post(url: requestURL, parameters: [
            "title" : title,
            "url" : data.base64EncodedURLString(),
            "version" : Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        ], success: { [unowned self] (result: URLCreationResponse) in
            alert.dismiss(animated: true) {
                guard let url = URL(string: result.publicURL) else {
                    showUnknownError()
                    return
                }
                self.showShareSheet(for: url)
            }
        }, failure: { (error) in
            alert.dismiss(animated: true) {
                showUnknownError()
            }
        })
    }

    private func showShareSheet(for url: URL) {
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        configurePopover(for: activityController)
        presentAfterDismissCurrent(activityController, animated: true)
    }
}

extension MainViewControler: UIViewControllerDismissDelegate {
    func viewControllerDidDismiss(_ viewController: UIViewController) {
        if (viewController.customFlag & userInitiatedDismissalFlag) == 0 {
            popLastAndShow()
        }
    }

    func popLastAndShow() {
        if let viewController = viewControllerStack.popLast() {
            showViewController(viewController)
        }
    }

    func clearBackStack() {
        viewControllerStack.removeAll()
    }

    func addToBackStack() {
        if let current = presentedViewController {
            viewControllerStack.append(current)
            current.customFlag |= userInitiatedDismissalFlag
            current.dismiss(animated: true, completion: nil)
        }
    }
}

#if targetEnvironment(macCatalyst)
extension MainViewControler: NSToolbarDelegate {
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
            [AppToolbarAction.browse, .favorite, .home].map { NSToolbarItem.Identifier($0.rawValue) } +
            [.flexibleSpace] +
            [AppToolbarAction.setting, .share, .search].map { NSToolbarItem.Identifier($0.rawValue) }
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
        let toolbar = NSToolbar(identifier: Bundle.main.bundleIdentifier!)
        toolbar.allowsUserCustomization = true
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
            core.back()
        } else {
            core.forward()
        }
    }
}

extension MainViewControler: NSTouchBarDelegate {
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
        case .reverse:
            return #imageLiteral(resourceName: "time_reverse")
        case .cancelScript:
            return #imageLiteral(resourceName: "time_stop")
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
        case .reverse:
            return UIImage(systemName: "repeat")
        case .cancelScript:
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
