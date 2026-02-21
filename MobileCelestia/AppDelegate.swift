// AppDelegate.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import AppIntents
import CelestiaCore
import CelestiaFoundation
#if targetEnvironment(macCatalyst)
import CelestiaHelper
#endif
import CelestiaUI
import Sentry
import UIKit

enum MenuBarAction: Hashable, Equatable {
    case captureImage
    case showAbout
    case selectSol
    case showSearch
    case showGoto
    case centerSelection
    case followSelection
    case gotoSelection
    case syncOrbitSelection
    case trackSelection
    case showFlightMode
    case showStarBrowser
    case showEclipseFinder
    case tenTimesFaster
    case tenTimesSlower
    case freezeTime
    case realTime
    case reverseTime
    case showTimeSetting
    case splitHorizontally
    case splitVertically
    case deleteActiveView
    case deleteOtherViews
    case runDemo
    case showOpenGLInfo
    case getAddons
    case showInstalledAddons
    case addBookmark
    case organizeBookmarks
    case reportBug
    case suggestFeature
    case celestiaPlus
    case getInfo
    case openAddonFolder
    case openScriptFolder
}

let newURLOpenedNotificationName = Notification.Name("NewURLOpenedNotificationName")
let newURLOpenedNotificationURLKey = "NewURLOpenedNotificationURLKey"
let showHelpNotificationName = Notification.Name("ShowHelpNotificationName")
let showPreferencesNotificationName = Notification.Name("ShowPreferencesNotificationName")
let requestOpenFileNotificationName = Notification.Name("RequestOpenFileNotificationName")
let menuBarActionNotificationName = Notification.Name("MenuBarNotificationName")
let menuBarActionNotificationKey = "MenuBarActionNotificationKey"
let requestRunScriptNotificationName = Notification.Name("RequestRunScriptNotificationName")
let requestRunScriptNotificationKey = Notification.Name("RequestRunScriptNotificationKey")
let requestOpenBookmarkNotificationName = Notification.Name("RequestOpenBookmarkNotificationName")
let requestOpenBookmarkNotificationKey = Notification.Name("RequestOpenBookmarkNotificationKey")

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
#if targetEnvironment(macCatalyst)
    private static let windowDidBecomeKeyNotification = NSNotification.Name("NSWindowDidBecomeKeyNotification")
#endif

    private enum MenuAction: Hashable, Equatable {
        case selector(_ selector: Selector)
        case name(_ name: String)
    }

    private var menuActions: [MenuAction] = [
        .selector(#selector(showHelp(_:))),
        .selector(#selector(copy(_:))),
        .selector(#selector(paste(_:))),
        .selector(#selector(showPreferences)),
        .selector(#selector(openScriptFile)),
        .selector(#selector(captureImage)),
        .selector(#selector(showAbout)),
        .selector(#selector(selectSol)),
        .selector(#selector(showSearch)),
        .selector(#selector(showGoto)),
        .selector(#selector(centerSelection)),
        .selector(#selector(gotoSelection)),
        .selector(#selector(followSelection)),
        .selector(#selector(syncOrbitSelection)),
        .selector(#selector(trackSelection)),
        .selector(#selector(showFlightMode)),
        .selector(#selector(showStarBrowser)),
        .selector(#selector(showEclipseFinder)),
        .selector(#selector(tenTimesFaster)),
        .selector(#selector(tenTimesSlower)),
        .selector(#selector(freezeTime)),
        .selector(#selector(realTime)),
        .selector(#selector(reverseTime)),
        .selector(#selector(showTimeSetting)),
        .selector(#selector(splitHorizontally)),
        .selector(#selector(splitVertically)),
        .selector(#selector(deleteActiveView)),
        .selector(#selector(deleteOtherViews)),
        .selector(#selector(runDemo)),
        .selector(#selector(showOpenGLInfo)),
        .selector(#selector(getAddons)),
        .selector(#selector(showInstalledAddons)),
        .selector(#selector(addBookmark)),
        .selector(#selector(organizeBookmarks)),
        .selector(#selector(reportBug)),
        .selector(#selector(suggestFeature)),
        .selector(#selector(showCelestiaPlus)),
        .selector(#selector(getInfo)),
        .selector(#selector(openAddonFolder)),
        .selector(#selector(openScriptFolder)),
    ]

    var window: UIWindow?

    lazy var core = AppCore()
    lazy var executor = CelestiaExecutor(core: core)
    lazy var userDefaults: UserDefaults = {
        let defaults = UserDefaults.standard
        defaults.initialize()
        return defaults
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CelestiaActor.underlyingExecutor = executor

        if #available(iOS 16, *) {
            let stateManager = StateManager.shared
            AppDependencyManager.shared.add(dependency: stateManager)
        }

        AppCore.setUpLocale()

        #if targetEnvironment(macCatalyst)
        MacBridge.initialize()

        if #available(macCatalyst 15.0, *) {
            if #available(macCatalyst 16.0, *) {
            } else {
                /// On macOS Catalyst 15.x-[UIFocusSytem _topEnvironment] throws a failed assertion `Expected a UIWindowScene but found (null).`
                /// when a window is closed with a list item focused. Swizzle to avoid the exception by catching it in Objective-C. FB9915023
                let selector = NSSelectorFromString("_topEnvironment")
                if UIFocusSystem.instancesRespond(to: selector),
                   let method = class_getInstanceMethod(UIFocusSystem.self, selector) {
                    let imp = method_getImplementation(method)
                    class_replaceMethod(UIFocusSystem.self, selector, imp_implementationWithBlock({ (self: UIFocusSystem) -> UIFocusEnvironment? in
                        var environment: UIFocusEnvironment?
                        ExceptionCatching.execute {
                            let oldIMP = unsafeBitCast(imp, to: (@convention(c) (UIFocusSystem, Selector) -> UIFocusEnvironment?).self)
                            environment = oldIMP(self, selector)
                        } exceptionHandler: { exception in
                            print("Ignoring exception: \(exception)")
                        }
                      return environment
                    } as @convention(block) (UIFocusSystem) -> UIFocusEnvironment?), method_getTypeEncoding(method))
                }
            }
        }

        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

        // Avoid reading saved state
        if let libraryURL = URL.library() {
            let savedStateURL = libraryURL.appendingPathComponent("Saved Application State")
            if FileManager.default.fileExists(atPath: savedStateURL.path) {
                try? FileManager.default.removeItem(at: savedStateURL)
            }
        }
        #endif

        #if !targetEnvironment(macCatalyst)
        // Swizzle accessibilityPerformEscape to support zorro gesture return
        let escapeSelector = #selector(UIViewController.accessibilityPerformEscape)
        if let escapeMethod = class_getInstanceMethod(UIViewController.self, escapeSelector) {
            let imp = method_getImplementation(escapeMethod)
            class_replaceMethod(UIViewController.self, escapeSelector, imp_implementationWithBlock({ (self: UIViewController) -> Bool in
                let oldIMP = unsafeBitCast(imp, to: (@convention(c) (UIViewController, Selector) -> Bool).self)
                var handled = oldIMP(self, escapeSelector)
                if !handled {
                    if self.parent == nil && (self.presentationController is SlideInPresentationController || self.presentationController is SheetPresentationController) {
                        self.presentingViewController?.dismiss(animated: true)
                        handled = true
                    }
                }
                return handled
            } as @convention(block) (UIViewController) -> Bool), method_getTypeEncoding(escapeMethod))
        }
        #endif

        #if targetEnvironment(macCatalyst)
        let dsn = "SENTRY-CATALYST-DSN"
        #else
        let dsn = "SENTRY-IOS-DSN"
        #endif
        SentrySDK.start { options in
            options.dsn = dsn
            #if DEBUG
            options.debug = true // Enabled debug when first installing is always helpful
            #endif
            options.tracesSampleRate = 0
            options.enableAutoPerformanceTracing = false
        }

        #if targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNSWindowDidBecomeKey(_:)), name: Self.windowDidBecomeKeyNotification, object: nil)
        #endif

        return true
    }

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return false
    }

    func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool {
        return false
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return false
    }

    func application(_ application: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
        return false
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        Self.handleUserActivity(userActivity)
        return true
    }

    #if targetEnvironment(macCatalyst)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if options.userActivities.contains(where: { $0.activityType == PanelSceneDelegate.activityType }) {
            return UISceneConfiguration(name: "Panel", sessionRole: .windowApplication)
        }
        return UISceneConfiguration(name: "Main", sessionRole: connectingSceneSession.role)
    }

    @objc private func handleNSWindowDidBecomeKey(_ notification: Notification) {
        guard let nsWindow = notification.object as? NSObject else { return }
        guard let scene = UIApplication.shared.connectedScenes.first(where: { scene in
            guard let windowScene = scene as? UIWindowScene else { return false }
            return windowScene.windows.contains { window in
                return window.nsWindow == nsWindow
            }
        }) else { return }

        MacBridge.disableRestorationForNSWindow(nsWindow)
        if scene.delegate is PanelSceneDelegate {
            if #available(iOS 16, *) {
            } else {
                MacBridge.disableFullScreenForNSWindow(nsWindow)
            }
        }
    }
    #endif

    @discardableResult static func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard let url = AppURL.from(userActivity: userActivity) else { return false }

        NotificationCenter.default.post(name: newURLOpenedNotificationName, object: nil, userInfo: [newURLOpenedNotificationURLKey: url])
        return true
    }

    override func validate(_ command: UICommand) {
        super.validate(command)
        if !core.isInitialized {
            if menuActions.contains(.selector(command.action)) {
                command.attributes.insert(.disabled)
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        let backgroundTaskID = application.beginBackgroundTask(expirationHandler: nil)
        if backgroundTaskID == .invalid {
            return
        }
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 5_000_000_000)
            application.endBackgroundTask(backgroundTaskID)
        }
    }
}

extension AppDelegate {
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        guard builder.system == .main else { return }

        builder.remove(menu: .newScene)
        builder.remove(menu: .edit)
        builder.remove(menu: .preferences)
        builder.remove(menu: .about)
        builder.remove(menu: .format)

        #if targetEnvironment(macCatalyst)
        let settingsTitle: String
        if #available(macCatalyst 16.0, *) {
            settingsTitle = CelestiaString("Settings…", comment: "")
        } else {
            settingsTitle = CelestiaString("Preferences…", comment: "Settings")
        }
        #else
        let settingsTitle = CelestiaString("Settings…", comment: "")
        #endif
        let aboutMenu = createMenuItem(
            identifierSuffix: "about",
            action: MenuActionContext(title: CelestiaString("About Celestia", comment: "System menu item"), action: #selector(showAbout))
        )
        builder.insertChild(aboutMenu, atStartOfMenu: .application)

        let celestiaPlusMenu = createMenuItem(identifierSuffix: "celestiaplus", action: MenuActionContext(title: CelestiaString("Celestia PLUS", comment: "Name for the subscription service"), action: #selector(showCelestiaPlus)))
        builder.insertSibling(celestiaPlusMenu, afterMenu: aboutMenu.identifier)

        let settingsMenu = createMenuItem(identifierSuffix: "preferences", action: MenuActionContext(title: settingsTitle, action: #selector(showPreferences), input: ",", modifierFlags: .command))
        builder.insertSibling(settingsMenu, afterMenu: celestiaPlusMenu.identifier)

        let runScriptMenu = createMenuItem(identifierSuffix: "open", action: MenuActionContext(title: CelestiaString("Run Script…", comment: ""), action: #selector(openScriptFile), input: "O", modifierFlags: .command))
        builder.insertChild(runScriptMenu, atStartOfMenu: .file)
        let captureImageKey = UIKeyCommand.f10
        let captureImageMenu = createMenuItem(identifierSuffix: "capture", action: MenuActionContext(title: CelestiaString("Capture Image", comment: "Take a screenshot in Celestia"), action: #selector(captureImage), input: captureImageKey))

        let scriptsMenu = createMenuItemGroupDeferred(title: CelestiaString("Scripts", comment: ""), identifierSuffix: "scripts") { [weak self] in
            guard let self else { return [] }
            guard self.core.isInitialized else { return [] }
            var scripts = Script.scripts(inDirectory: "scripts", deepScan: true)
            if let extraScriptsDirectory = UserDefaults.extraScriptDirectory {
                scripts += Script.scripts(inDirectory: extraScriptsDirectory.path, deepScan: true)
            }
            return scripts.map { script in
                UIAction(title: script.title) { _ in
                    NotificationCenter.default.post(name: requestRunScriptNotificationName, object: nil, userInfo: [requestRunScriptNotificationKey: script])
                }
            }
        }
        builder.insertSibling(scriptsMenu, beforeMenu: .close)
        builder.insertSibling(captureImageMenu, afterMenu: scriptsMenu.identifier)
        let copyPasteMenu = createMenuItemGroup(identifierSuffix: "copypaste", actions: [
            MenuActionContext(title: CelestiaString("Copy", comment: "Copy current URL to pasteboard"), action: #selector(copy(_:)), input: "c", modifierFlags: .command),
            MenuActionContext(title: CelestiaString("Paste", comment: "Paste URL from pasteboard"), action: #selector(paste(_:)), input: "v", modifierFlags: .command),
        ])
        builder.insertSibling(copyPasteMenu, afterMenu: captureImageMenu.identifier)

        let navigationMenu = createMenuItemGroup(title: CelestiaString("Navigation", comment: "Navigation menu"), identifierSuffix: "navigation", actions: [], options: [])
        builder.insertSibling(navigationMenu, afterMenu: .file)

        let getInfoMenu = createMenuItemGroup(identifierSuffix: "getinfo", actions: [
            MenuActionContext(title: CelestiaString("Get Info", comment: "Action for getting info about current selected object"), action: #selector(getInfo)),
        ])
        builder.insertChild(getInfoMenu, atStartOfMenu: navigationMenu.identifier)

        let selectMenu = createMenuItemGroup(identifierSuffix: "select", actions: [
            MenuActionContext(title: CelestiaString("Select Sol", comment: ""), action: #selector(selectSol), input: "h"),
            MenuActionContext(title: CelestiaString("Search…", comment: "Menu item to start searching"), action: #selector(showSearch)),
            MenuActionContext(title: CelestiaString("Go to Object", comment: ""), action: #selector(showGoto)),
        ])
        builder.insertSibling(selectMenu, afterMenu: getInfoMenu.identifier)

        let selectionActionMenu = createMenuItemGroup(identifierSuffix: "selection.actions", actions: [
            MenuActionContext(title: CelestiaString("Center Selection", comment: "Center selected object"), action: #selector(centerSelection), input: "c"),
            MenuActionContext(title: CelestiaString("Go to Selection", comment: "Go to selected object"), action: #selector(gotoSelection), input: "g"),
            MenuActionContext(title: CelestiaString("Follow Selection", comment: ""), action: #selector(followSelection), input: "f"),
            MenuActionContext(title: CelestiaString("Sync Orbit Selection", comment: ""), action: #selector(syncOrbitSelection), input: "y"),
            MenuActionContext(title: CelestiaString("Track Selection", comment: "Track selected object"), action: #selector(trackSelection), input: "t"),
        ])
        builder.insertSibling(selectionActionMenu, afterMenu: selectMenu.identifier)
        builder.insertSibling(createMenuItem(identifierSuffix: "flightmode", action: MenuActionContext(title: CelestiaString("Flight Mode", comment: ""), action: #selector(showFlightMode))), afterMenu: selectionActionMenu.identifier)

        let toolsMenu = createMenuItemGroup(title: CelestiaString("Tools", comment: "Tools menu title"), identifierSuffix: "tools", actions: [], options: [])
        builder.insertSibling(toolsMenu, afterMenu: navigationMenu.identifier)
        let mainToolsMenu = createMenuItemGroup(identifierSuffix: "tools.main", actions: [
            MenuActionContext(title: CelestiaString("Star Browser", comment: ""), action: #selector(showStarBrowser)),
            MenuActionContext(title: CelestiaString("Eclipse Finder", comment: ""), action: #selector(showEclipseFinder)),
        ])
        builder.insertChild(mainToolsMenu, atStartOfMenu: toolsMenu.identifier)
        let addonToolsMenu = createMenuItemGroup(identifierSuffix: "tools.addon", actions: [
            MenuActionContext(title: CelestiaString("Get Add-ons", comment: "Open webpage for downloading add-ons"), action: #selector(getAddons)),
            MenuActionContext(title: CelestiaString("Installed Add-ons", comment: "Open a page for managing installed add-ons"), action: #selector(showInstalledAddons)),
        ])
        builder.insertSibling(addonToolsMenu, afterMenu: mainToolsMenu.identifier)
#if targetEnvironment(macCatalyst)
        let openFoldersMenu = createMenuItemGroup(identifierSuffix: "tools.folders", actions: [
            MenuActionContext(title: CelestiaString("Open Add-on Folder", comment: "Open the folder for add-ons"), action: #selector(openAddonFolder)),
            MenuActionContext(title: CelestiaString("Open Script Folder", comment: "Open the folder for scripts"), action: #selector(openScriptFolder)),
        ])
        builder.insertSibling(openFoldersMenu, afterMenu: addonToolsMenu.identifier)
#endif

        let timeMenu = createMenuItemGroup(title: CelestiaString("Time", comment: ""), identifierSuffix: "time", actions: [], options: [])
        builder.insertSibling(timeMenu, afterMenu: toolsMenu.identifier)
        let quickTimeSettingMenu = createMenuItemGroup(identifierSuffix: "time.quick", actions: [
            MenuActionContext(title: CelestiaString("10x Faster", comment: "10x time speed"), action: #selector(tenTimesFaster), input: "l"),
            MenuActionContext(title: CelestiaString("10x Slower", comment: "0.1x time speed"), action: #selector(tenTimesSlower), input: "k"),
            MenuActionContext(title: CelestiaString("Freeze", comment: "Freeze time"), action: #selector(freezeTime), input: " "),
            MenuActionContext(title: CelestiaString("Real Time", comment: "Reset time speed to 1x"), action: #selector(realTime)),
            MenuActionContext(title: CelestiaString("Reverse Time", comment: ""), action: #selector(reverseTime), input: "j"),
        ])
        builder.insertChild(quickTimeSettingMenu, atStartOfMenu: timeMenu.identifier)
        builder.insertSibling(createMenuItem(identifierSuffix: "time.select", action: MenuActionContext(title: CelestiaString("Set Time…", comment: "Select simulation time"), action: #selector(showTimeSetting))), afterMenu: quickTimeSettingMenu.identifier)

        let bookmarkMenu = createMenuItemGroup(title: CelestiaString("Bookmarks", comment: "URL bookmarks"), identifierSuffix: "bookmarks", actions: [], options: [])
        builder.insertSibling(bookmarkMenu, afterMenu: timeMenu.identifier)
        let bookmarkActionMenu = createMenuItemGroup(identifierSuffix: "bookmark.actions", actions: [
            MenuActionContext(title: CelestiaString("Add Bookmark", comment: "Add a new bookmark"), action: #selector(addBookmark)),
            MenuActionContext(title: CelestiaString("Organize Bookmarks…", comment: ""), action: #selector(organizeBookmarks)),
        ])
        builder.insertChild(bookmarkActionMenu, atStartOfMenu: bookmarkMenu.identifier)
        let openBookmarkMenu = createMenuItemGroupDeferred(identifierSuffix: "bookmark.open", options: .displayInline) { [weak self] in
            guard let self else { return [] }
            guard self.core.isInitialized else { return [] }
            let bookmarks = readBookmarks()
            // Only leaf bookmarks on top level
            return bookmarks.filter { $0.isLeaf }.map { bookmark in
                UIAction(title: bookmark.name) { _ in
                    NotificationCenter.default.post(name: requestOpenBookmarkNotificationName, object: nil, userInfo: [requestOpenBookmarkNotificationKey: bookmark])
                }
            }
        }
        builder.insertSibling(openBookmarkMenu, afterMenu: bookmarkActionMenu.identifier)

        let deleteActiveViewKey = String(Character(UnicodeScalar(0x7f)))
        builder.insertChild(createMenuItemGroup(identifierSuffix: "views", actions: [
            MenuActionContext(title: CelestiaString("Split Horizontally", comment: "Split view"), action: #selector(splitHorizontally), input: "r", modifierFlags: .control),
            MenuActionContext(title: CelestiaString("Split Vertically", comment: "Split view"), action: #selector(splitVertically), input: "u", modifierFlags: .control),
            MenuActionContext(title: CelestiaString("Delete Active View", comment: "Delete current view (in split view mode)"), action: #selector(deleteActiveView), input: deleteActiveViewKey),
            MenuActionContext(title: CelestiaString("Delete Other Views", comment: "Delete views other than current view (in split view mode)"), action: #selector(deleteOtherViews), input: "d", modifierFlags: .control),
        ]), atStartOfMenu: .view)

        let runDemoMenu = createMenuItem(identifierSuffix: "help.demo", action: MenuActionContext(title: CelestiaString("Run Demo", comment: ""), action: #selector(runDemo), input: ""))
        builder.insertChild(runDemoMenu, atEndOfMenu: .help)
        let openGLMenu = createMenuItem(identifierSuffix: "help.opengl", action: MenuActionContext(title: CelestiaString("OpenGL Info", comment: ""), action: #selector(showOpenGLInfo)))
        builder.insertSibling(openGLMenu, afterMenu: runDemoMenu.identifier)

        let feedbackActionMenu = createMenuItemGroup(identifierSuffix: "feedback", actions: [
            MenuActionContext(title: CelestiaString("Report a Bug", comment: ""), action: #selector(reportBug)),
            MenuActionContext(title: CelestiaString("Suggest a Feature", comment: ""), action: #selector(suggestFeature)),
        ])
        builder.insertSibling(feedbackActionMenu, afterMenu: openGLMenu.identifier)
    }

    private struct MenuActionContext {
        enum Input {
            case none
            case key(input: String, modifierFlags: UIKeyModifierFlags)
        }
        let title: String
        let action: Selector
        let input: Input

        init(title: String, action: Selector, input: String = "", modifierFlags: UIKeyModifierFlags = []) {
            self.title = title
            self.action = action
            if input.isEmpty {
                self.input = .none
            } else {
                self.input = .key(input: input, modifierFlags: modifierFlags)
            }
        }
    }

    private func createMenuItem(identifierSuffix: String, action: MenuActionContext) -> UIMenu {
        createMenuItemGroup(title: "", identifierSuffix: identifierSuffix, actions: [action], options: .displayInline)
    }

    private func createMenuItemGroupDeferred(title: String = "", identifierSuffix: String, options: UIMenu.Options = [], menuBuilder: @escaping @MainActor () async -> [UIAction]) -> UIMenu {
        let identifierPrefix = Bundle.app.bundleIdentifier! + "."
        let identifier = UIMenu.Identifier(identifierPrefix + identifierSuffix)
        return UIMenu(title: title, identifier: identifier, options: options, children: [UIDeferredMenuElement.uncached { completion in
            Task { @MainActor in
                let items = await menuBuilder()
                completion(items)
            }
        }])
    }

    private func createMenuItemCommand(_ action: MenuActionContext) -> UICommand {
        switch action.input {
        case let .key(input, modifierFlags):
            return UIKeyCommand(title: action.title, action: action.action, input: input, modifierFlags: modifierFlags)
        case .none:
            return UICommand(title: action.title, action: action.action)
        }
    }

    private func createMenuItemGroup(title: String = "", identifierSuffix: String, actions: [MenuActionContext], options: UIMenu.Options = .displayInline) -> UIMenu {
        let identifierPrefix = Bundle.app.bundleIdentifier! + "."
        let identifier = UIMenu.Identifier(identifierPrefix + identifierSuffix)
        return UIMenu(
            title: title, image: nil, identifier: identifier, options: options,
            children: actions.map({ createMenuItemCommand($0) })
        )
    }

    @objc private func openScriptFile() {
        NotificationCenter.default.post(name: requestOpenFileNotificationName, object: nil)
    }

    @objc private func showHelp(_ sender: Any) {
        NotificationCenter.default.post(name: showHelpNotificationName, object: nil, userInfo: nil)
    }

    @objc private func showPreferences() {
        NotificationCenter.default.post(name: showPreferencesNotificationName, object: nil, userInfo: nil)
    }

    @objc private func captureImage() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.captureImage])
    }

    @objc private func showAbout() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.showAbout])
    }

    @objc private func selectSol() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.selectSol])
    }

    @objc private func getInfo() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.getInfo])
    }

    @objc private func showSearch() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.showSearch])
    }

    @objc private func showGoto() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.showGoto])
    }

    @objc private func centerSelection() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.centerSelection])
    }

    @objc private func gotoSelection() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.gotoSelection])
    }

    @objc private func followSelection() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.followSelection])
    }

    @objc private func syncOrbitSelection() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.syncOrbitSelection])
    }

    @objc private func trackSelection() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.trackSelection])
    }

    @objc private func showFlightMode() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.showFlightMode])
    }

    @objc private func showStarBrowser() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.showStarBrowser])
    }

    @objc private func showEclipseFinder() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.showEclipseFinder])
    }

    @objc private func tenTimesFaster() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.tenTimesFaster])
    }

    @objc private func tenTimesSlower() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.tenTimesSlower])
    }

    @objc private func freezeTime() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.freezeTime])
    }

    @objc private func realTime() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.realTime])
    }

    @objc private func reverseTime() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.reverseTime])
    }

    @objc private func showTimeSetting() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.showTimeSetting])
    }

    @objc private func splitHorizontally() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.splitHorizontally])
    }

    @objc private func splitVertically() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.splitVertically])
    }

    @objc private func deleteActiveView() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.deleteActiveView])
    }

    @objc private func deleteOtherViews() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.deleteOtherViews])
    }

    @objc private func runDemo() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.runDemo])
    }

    @objc private func showOpenGLInfo() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.showOpenGLInfo])
    }

    @objc private func getAddons() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.getAddons])
    }

    @objc private func showInstalledAddons() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.showInstalledAddons])
    }

    @objc private func openAddonFolder() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.openAddonFolder])
    }

    @objc private func openScriptFolder() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.openScriptFolder])
    }

    @objc private func addBookmark() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.addBookmark])
    }

    @objc private func organizeBookmarks() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.organizeBookmarks])
    }

    @objc private func reportBug() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.reportBug])
    }

    @objc private func suggestFeature() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.suggestFeature])
    }

    @objc private func showCelestiaPlus() {
        NotificationCenter.default.post(name: menuBarActionNotificationName, object: nil, userInfo: [menuBarActionNotificationKey: MenuBarAction.celestiaPlus])
    }
}

#if targetEnvironment(macCatalyst)
class MacBridge {
    private static let clazz = NSClassFromString("CELMacBridge") as! NSObject.Type // Should only be used after calling initialize

    static func initialize() {
        guard let appBundleUrl = Bundle.app.builtInPlugInsURL else { return }
        let helperBundleUrl = appBundleUrl.appendingPathComponent("CelestiaMacBridge.bundle")
        guard let bundle = Bundle(url: helperBundleUrl) else { return }
        bundle.load()
    }

    static var catalystScaleFactor: CGFloat {
        return (clazz.value(forKey: "catalystScaleFactor") as? CGFloat) ?? 1.0
    }

    static var currentMouseLocation: CGPoint? {
        return clazz.value(forKey: "currentMouseLocation") as? CGPoint
    }

    static func nsWindowForUIWindow(_ uiWindow: UIWindow) -> NSObject? {
        return clazz.perform(NSSelectorFromString("nsWindowForUIWindow:"), with: uiWindow)?.takeUnretainedValue() as? NSObject
    }

    static func disableRestorationForNSWindow(_ nsWindow: NSObject) {
        clazz.perform(NSSelectorFromString("disableRestorationForNSWindow:"), with: nsWindow)
    }

    static func disableFullScreenForNSWindow(_ nsWindow: NSObject) {
        clazz.perform(NSSelectorFromString("disableFullScreenForNSWindow:"), with: nsWindow)
    }

    static func showTextInputSheetForWindow(_ window: NSObject, title: String, message: String? = nil, text: String? = nil, placeholder: String? = nil, okButtonTitle: String, cancelButtonTitle: String, completion: @escaping (String?) -> Void) {
        typealias ShowTextInputMethod = @convention(c)
        (NSObject.Type, Selector, NSObject, NSString, NSString?, NSString?, NSString?, NSString, NSString, @escaping (NSString?) -> Void) -> Void
        let selector = NSSelectorFromString("showTextInputSheetForWindow:title:message:text:placeholder:okButtonTitle:cancelButtonTitle:completionHandler:")
        let methodIMP = clazz.method(for: selector)
        let method = unsafeBitCast(methodIMP, to: ShowTextInputMethod.self)
        method(clazz, selector, window, title as NSString, message as NSString?, text as NSString?, placeholder as NSString?, okButtonTitle as NSString, cancelButtonTitle as NSString, { result in
            completion(result as String?)
        })
    }

    static func addRecentURL(_ url: URL) {
        clazz.perform(NSSelectorFromString("addRecentOpenedFile:"), with: url)
    }

    static func openFolderURL(_ folderURL: URL) {
        clazz.perform(NSSelectorFromString("openFolder:"), with: folderURL)
    }

    static func terminateApp() {
        clazz.perform(NSSelectorFromString("terminateApp"))
    }
}

extension UIWindow {
    var nsWindow: NSObject? {
        return MacBridge.nsWindowForUIWindow(self)
    }
}
#endif
