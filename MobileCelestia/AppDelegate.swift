//
// AppDelegate.swift
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

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

let newURLOpenedNotificationName = Notification.Name("NewURLOpenedNotificationName")
let newURLOpenedNotificationURLKey = "NewURLOpenedNotificationURLKey"
let showHelpNotificationName = Notification.Name("ShowHelpNotificationName")
let showPreferencesNotificationName = Notification.Name("ShowPreferencesNotificationName")
let requestOpenFileNotificationName = Notification.Name("RequestOpenFileNotificationName")
let requestCopyNotificationName = Notification.Name("RequestCopyNotificationName")
let requestPasteNotificationName = Notification.Name("RequestPasteNotificationName")

let officialWebsiteURL = URL(string: "https://celestia.mobi")!
let supportForumURL = URL(string: "https://celestia.space/forum")!
let apiPrefix = "https://celestia.mobi/api"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if targetEnvironment(macCatalyst)
        MacBridge.initialize()

        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

        // Force dark aqua appearance
        MacBridge.forceDarkAppearance()
        MacBridge.disableTabbingForAllWindows()

        // Avoid reading saved state
        if let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
            let savedStatePath = "\(libraryPath)/Saved Application State"
            if FileManager.default.fileExists(atPath: savedStatePath) {
                try? FileManager.default.removeItem(atPath: savedStatePath)
            }
        }
        #else
        UISlider.appearance().minimumTrackTintColor = .darkSliderMinimumTrackTintColor
        UISlider.appearance().maximumTrackTintColor = .darkSliderMaximumTrackTintColor
        UIBarButtonItem.appearance().tintColor = .themeLabel
        UIButton.appearance().tintColor = .themeLabel
        UITabBar.appearance().tintColor = .themeLabel
        UISearchBar.appearance().tintColor = .themeLabel
        UISegmentedControl.appearance().tintColor = .themeLabel
        #endif

        #if !DEBUG
        #if targetEnvironment(macCatalyst)
        let appCenterID = "63a9e404-a07b-40eb-a5e7-320f65934b05"
        #else
        let appCenterID = "4c46cd7d-ea97-452b-920c-4328ac062db3"
        #endif
        AppCenter.start(withAppSecret: appCenterID, services: [
            Analytics.self,
            Crashes.self
        ])
        #endif

        if #available(iOS 13.0, *) { return true }

        window = UIWindow()

        var launchURL: UniformedURL?
        if let url = launchOptions?[.url] as? URL {
            launchURL = UniformedURL(url: url, securityScoped: url.isFileURL)
        }
        let vc = MainViewController(initialURL: launchURL)

        window?.rootViewController = vc
        window?.makeKeyAndVisible()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        NotificationCenter.default.post(name: newURLOpenedNotificationName, object: nil, userInfo: [
            newURLOpenedNotificationURLKey: UniformedURL(url: url, securityScoped: url.isFileURL && options[.openInPlace] as? Bool == true),
        ])
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
    @available(iOS 13, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if options.userActivities.contains(where: { $0.activityType == PanelSceneDelegate.activityType }) {
            return UISceneConfiguration(name: "Panel", sessionRole: .windowApplication)
        }
        return UISceneConfiguration(name: "Main", sessionRole: connectingSceneSession.role)
    }
    #endif

    @discardableResult static func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard let url = userActivity.webpageURL else { return false }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        // Path and ID are needed to resolve a URL with API
        guard let id = components.queryItems?.first(where: { $0.name == "id" })?.value else { return false }
        let path = components.path

        struct Response: Decodable {
            let resolvedURL: URL
        }

        // Make request to the server to resolve the URL
        let requestURL = apiPrefix + "/resolve"
        _ = RequestHandler.get(url: requestURL, parameters: ["path" : path, "id" : id], success: { (response: Response) in
            NotificationCenter.default.post(name: newURLOpenedNotificationName, object: nil, userInfo: [newURLOpenedNotificationURLKey: UniformedURL(url: response.resolvedURL, securityScoped: false)])
        })
        return true
    }

    override func copy(_ sender: Any?) {
        NotificationCenter.default.post(name: requestCopyNotificationName, object: nil)
    }

    override func paste(_ sender: Any?) {
        NotificationCenter.default.post(name: requestPasteNotificationName, object: nil)
    }

    @available(iOS 13, *)
    override func validate(_ command: UICommand) {
        super.validate(command)
        let actionName = NSStringFromSelector(command.action)
        if !CelestiaAppCore.shared.isInitialized {
            if command.action == #selector(showPreferences) || command.action == #selector(openScriptFile) || actionName == "copy:" || actionName == "paste:" || command.action == #selector(showHelp(_:)) {
                command.attributes = .disabled
            }
        }
    }
}

@available(iOS 13.0, *)
extension AppDelegate {
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        guard builder.system == .main else { return }

        builder.remove(menu: .newScene)

        let identifierPrefix = Bundle.app.bundleIdentifier! + "."

        let preferencesCommand = UIKeyCommand(title: CelestiaString("Preferences…", comment: ""), action: #selector(showPreferences), input: ",", modifierFlags: .command)
        builder.insertSibling(UIMenu(identifier: UIMenu.Identifier(identifierPrefix + "preferences"), options: .displayInline, children: [
            preferencesCommand
        ]), afterMenu: .about)

        builder.insertChild(UIMenu(title: "", image: nil, identifier: UIMenu.Identifier(identifierPrefix + "open"), options: .displayInline, children: [
            UIKeyCommand(title: CelestiaString("Run Script…", comment: ""), image: nil, action: #selector(openScriptFile), input: "O", modifierFlags: .command)
        ]), atStartOfMenu: .file)
    }

    @objc private func openScriptFile() {
        NotificationCenter.default.post(name: requestOpenFileNotificationName, object: nil)
    }

    @objc private func showHelp(_ sender: Any) {
        NotificationCenter.default.post(name: showHelpNotificationName, object: nil, userInfo: nil)
    }

    @objc private func openOfficialWebsite() {
        UIApplication.shared.open(officialWebsiteURL, options: [:], completionHandler: nil)
    }

    @objc private func openSupportForum() {
        UIApplication.shared.open(supportForumURL, options: [:], completionHandler: nil)
    }

    @objc private func showPreferences() {
        NotificationCenter.default.post(name: showPreferencesNotificationName, object: nil, userInfo: nil)
    }
}

#if targetEnvironment(macCatalyst)
class MacBridge {
    private static var clazz = NSClassFromString("MacBridge") as! NSObject.Type // Should only be used after calling initialize

    static func initialize() {
        guard let appBundleUrl = Bundle.app.builtInPlugInsURL else { return }
        let helperBundleUrl = appBundleUrl.appendingPathComponent("CelestiaMacBridge.bundle")
        guard let bundle = Bundle(url: helperBundleUrl) else { return }
        bundle.load()
    }

    static var catalystScaleFactor: CGFloat {
        return (clazz.value(forKey: "catalystScaleFactor") as? CGFloat) ?? 1.0
    }

    static func forceDarkAppearance() {
        clazz.perform(NSSelectorFromString("forceDarkAppearance"))
    }

    static func nsWindowForUIWindow(_ uiWindow: UIWindow) -> NSObject? {
        return clazz.perform(NSSelectorFromString("nsWindowForUIWindow:"), with: uiWindow)?.takeUnretainedValue() as? NSObject
    }

    static func disableFullScreenForNSWindow(_ nsWindow: NSObject) {
        clazz.perform(NSSelectorFromString("disableFullScreenForNSWindow:"), with: nsWindow)
    }

    static func disableTabbingForAllWindows() {
        clazz.perform(NSSelectorFromString("disableTabbingForAllWindows"))
    }
}
#endif
