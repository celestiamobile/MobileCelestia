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
#if targetEnvironment(macCatalyst)
import CelestiaHelper
#endif

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

let newURLOpenedNotificationName = Notification.Name("NewURLOpenedNotificationName")
let newURLOpenedNotificationURLKey = "NewURLOpenedNotificationURLKey"
let newAddonOpenedNotificationName = Notification.Name("NewAddonOpenedNotificationName")
let newAddonOpenedNotificationIDKey = "NewAddonOpenedNotificationIDKey"
let newGuideOpenedNotificationName = Notification.Name("NewGuideOpenedNotificationName")
let newGuideOpenedNotificationIDKey = "NewGuideOpenedNotificationIDKey"
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

    @Injected(\.appCore) private var core

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        setlocale(LC_ALL, "")
        setlocale(LC_NUMERIC, "C")

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
        UISlider.appearance().minimumTrackTintColor = .themeLabel
        UISlider.appearance().maximumTrackTintColor = .darkSystemFill
        UISwitch.appearance().onTintColor = .themeLabel
        UIBarButtonItem.appearance().tintColor = .themeLabel
        UIButton.appearance().tintColor = .themeLabel
        UITabBar.appearance().tintColor = .themeLabel
        UISearchBar.appearance().tintColor = .themeLabel
        UISegmentedControl.appearance().tintColor = .themeLabel
        UIProgressView.appearance().trackTintColor = .progressBackground
        UIProgressView.appearance().progressTintColor = .progressForeground
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .themeLabel
        #endif

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

        #if !DEBUG
        #if targetEnvironment(macCatalyst)
        let appCenterID = "APPCENTER-APP-CATALYST"
        #else
        let appCenterID = "APPCENTER-APP-IOS"
        #endif
        AppCenter.start(withAppSecret: appCenterID, services: [
            Analytics.self,
            Crashes.self
        ])
        #endif
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
        if options.userActivities.contains(where: { $0.activityType == DisplaySceneDelegate.activityType }) {
            return UISceneConfiguration(name: "Display", sessionRole: .windowApplication)
        }
        return UISceneConfiguration(name: "Main", sessionRole: connectingSceneSession.role)
    }
    #endif

    @discardableResult static func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard let url = userActivity.webpageURL else { return false }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        if components.path == "/resources/item" {
            // Handle shared add-on
            guard let id = components.queryItems?.first(where: { $0.name == "item" })?.value else { return false }

            NotificationCenter.default.post(name: newAddonOpenedNotificationName, object: nil, userInfo: [newAddonOpenedNotificationIDKey: id])
            return true
        } else if components.path == "/resources/guide" {
            // Handle shared add-on
            guard let id = components.queryItems?.first(where: { $0.name == "guide" })?.value else { return false }

            NotificationCenter.default.post(name: newGuideOpenedNotificationName, object: nil, userInfo: [newGuideOpenedNotificationIDKey: id])
            return true
        }
        return false
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
        if !core.isInitialized {
            if command.action == #selector(showPreferences) || command.action == #selector(openScriptFile) || actionName == "copy:" || actionName == "paste:" || command.action == #selector(showHelp(_:)) {
                command.attributes = .disabled
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        let backgroundTaskID = application.beginBackgroundTask(expirationHandler: nil)
        if backgroundTaskID == .invalid {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            application.endBackgroundTask(backgroundTaskID)
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

        #if targetEnvironment(macCatalyst)
        let settingsTitle: String
        if #available(macCatalyst 16.0, *) {
            settingsTitle = CelestiaString("Settings…", comment: "")
        } else {
            settingsTitle = CelestiaString("Preferences…", comment: "")
        }
        #else
        let settingsTitle = CelestiaString("Settings…", comment: "")
        #endif
        let preferencesCommand = UIKeyCommand(title: settingsTitle, action: #selector(showPreferences), input: ",", modifierFlags: .command)
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
}

extension UIWindow {
    var nsWindow: NSObject? {
        return MacBridge.nsWindowForUIWindow(self)
    }
}
#endif
