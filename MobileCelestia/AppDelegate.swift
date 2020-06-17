//
//  AppDelegate.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/20.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

#if !targetEnvironment(macCatalyst)
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
#endif

let newURLOpenedNotificationName = Notification.Name("newURLOpenedNotificationName")
let newURLOpenedNotificationURLKey = "newURLOpenedNotificationURLKey"
let showHelpNotificationName = Notification.Name("showHelpNotificationName")

let officialWebsiteURL = URL(string: "https://celestia.space")!
let supportForumURL = URL(string: "https://celestia.space/forum")!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        swizzleShouldInheritScreenScaleAsContentScaleFactor()

        #if !targetEnvironment(macCatalyst)
        #if !DEBUG
        MSAppCenter.start("4c46cd7d-ea97-452b-920c-4328ac062db3", withServices:[
            MSAnalytics.self,
            MSCrashes.self
        ])
        #endif
        #endif

        window = UIWindow()
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .dark
        }
        let vc = MainViewControler()

        window?.rootViewController = vc
        window?.makeKeyAndVisible()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        urlToRun = url

        NotificationCenter.default.post(name: newURLOpenedNotificationName, object: nil, userInfo: [newURLOpenedNotificationURLKey : url])
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        let core = CelestiaAppCore.shared
        if core.isInitialized {
            core.storeUserDefaults()
        }
    }
}

extension AppDelegate: UIDocumentPickerDelegate {
    override func buildMenu(with builder: UIMenuBuilder) {
        guard builder.system == .main else { return }

        let identifierPrefix = Bundle.main.bundleIdentifier! + "."

        builder.insertChild(UIMenu(title: "", image: nil, identifier: UIMenu.Identifier(identifierPrefix + "open"), options: .displayInline, children: [
            UIKeyCommand(title: CelestiaString("Run Script…", comment: ""), image: nil, action: #selector(openScriptFile), input: "O", modifierFlags: .command)
        ]), atStartOfMenu: .file)
        builder.replace(menu: .help, with: UIMenu(title: CelestiaString("Help", comment: ""), image: nil, identifier: UIMenu.Identifier(identifierPrefix + "help"), children: [
            UICommand(title: CelestiaString("Celestia Help", comment: ""), image: nil, action: #selector(showCelestiaHelp(_:))),
            UIMenu(title: "", image: nil, identifier: UIMenu.Identifier(identifierPrefix + "help.sub"), options: .displayInline, children: [
                UICommand(title: CelestiaString("Official Website", comment: ""), image: nil, action: #selector(openOfficialWebsite)),
                UICommand(title: CelestiaString("Support Forum", comment: ""), image: nil, action: #selector(openSupportForum)),
            ])
        ]))
    }

    @objc private func openScriptFile() {
        guard let presenting = UIApplication.shared.delegate?.window??.rootViewController else { return }
        let types = ["space.celestia.script", "public.flc-animation"]
        let browser = UIDocumentPickerViewController(documentTypes: types, in: .open)
        browser.allowsMultipleSelection = false
        browser.delegate = self
        presenting.present(browser, animated: true, completion: nil)
    }

    @objc private func showCelestiaHelp(_ sender: Any) {
        NotificationCenter.default.post(name: showHelpNotificationName, object: nil, userInfo: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        urlToRun = url

        NotificationCenter.default.post(name: newURLOpenedNotificationName, object: nil, userInfo: [newURLOpenedNotificationURLKey : url])
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(openScriptFile) || action == #selector(showCelestiaHelp(_:)) {
            let presenting = UIApplication.shared.delegate?.window??.rootViewController
            return presenting != nil && presenting?.presentedViewController == nil
        }
        return super.canPerformAction(action, withSender: sender)
    }

    @objc private func openOfficialWebsite() {
        UIApplication.shared.open(officialWebsiteURL, options: [:], completionHandler: nil)
    }

    @objc private func openSupportForum() {
        UIApplication.shared.open(supportForumURL, options: [:], completionHandler: nil)
    }
}

extension AppDelegate {
    private func swizzleShouldInheritScreenScaleAsContentScaleFactor() {
        #if USE_MGL
        let clazz = MGLKView.self
        let selector = NSSelectorFromString("_shouldInheritScreenScaleAsContentScaleFactor")
        guard let method = class_getInstanceMethod(clazz, selector) else { return }
        class_replaceMethod(clazz, selector, imp_implementationWithBlock({ (_: MGLKView) -> Bool in
            return false
        } as @convention(block) (MGLKView) -> Bool), method_getTypeEncoding(method))
        #endif
    }
}
