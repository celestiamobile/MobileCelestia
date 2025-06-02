//
// PanelSceneDelegate.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaFoundation
import CelestiaUI
import UIKit

#if targetEnvironment(macCatalyst)
class PanelSceneDelegate: CommonSceneDelegate {
    var window: UIWindow?
    private var titleObservation: NSKeyValueObservation?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        guard let userInfo = connectionOptions.userActivities.first?.userInfo else { return }
        guard let id = userInfo[Self.idKey] as? UUID, let width = userInfo[Self.widthKey] as? CGFloat, let height = userInfo[Self.heightKey] as? CGFloat, let titleVisible = userInfo[Self.titleVisibleKey] as? Bool, let showsToolbar = userInfo[Self.customToolbarKey] as? Bool else { return }
        guard let sessionKey = userInfo[Self.sessionKey] as? String else { return }
        guard let viewController = Self.viewControllersToPresent.removeValue(forKey: id) else { return }
        let size = CGSize(width: width, height: height)
        Self.weakSessionTable.setObject(session, forKey: sessionKey as NSString)

        windowScene.titlebar?.titleVisibility = titleVisible ? .visible : .hidden
        windowScene.titlebar?.toolbarStyle = .unifiedCompact
        titleObservation = viewController.observe(\.windowTitle, options: [.initial, .new]) { [weak windowScene] (viewController, _) in
            Task { @MainActor in
                guard let windowScene = windowScene else { return }
                windowScene.title = viewController.windowTitle
            }
        }

        if showsToolbar {
            let toolbar = NSToolbar(identifier: UUID().uuidString)
            if #available(iOS 18, *) {
                toolbar.allowsDisplayModeCustomization = false
            }
            toolbar.displayMode = .iconOnly
            toolbar.allowsUserCustomization = false
            toolbar.autosavesConfiguration = false
            windowScene.titlebar?.toolbar = toolbar
            if let toolbarAwareVC = viewController as? ToolbarContainerViewController {
                toolbarAwareVC.nsToolbar = toolbar
            }
        }
        windowScene.sizeRestrictions?.minimumSize = size
        windowScene.sizeRestrictions?.maximumSize = size
        if #available(iOS 16.0, *) {
            windowScene.sizeRestrictions?.allowsFullScreen = false
        }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = viewController

        self.window = window
        window.makeKeyAndVisible()
    }

    static var activityType = "\(Bundle.app.bundleIdentifier!).Panel"
    private static var idKey = "id"
    private static var widthKey = "width"
    private static var heightKey = "height"
    private static var titleVisibleKey = "title_visible"
    private static var customToolbarKey = "custom_toolbar"
    private static var sessionKey = "session"
    private static var viewControllersToPresent: [UUID : UIViewController] = [:]
    private static var weakSessionTable = NSMapTable<NSString, UISceneSession>(keyOptions: .strongMemory, valueOptions: .weakMemory)

    static func present(_ viewController: UIViewController, key: String?, preferredSize: CGSize, titleVisible: Bool, customToolbar: Bool) {
        let sessionTableKey: String
        if let key {
            sessionTableKey = key
        } else {
            if let nav = viewController as? UINavigationController, let root = nav.viewControllers.first {
                sessionTableKey = String(describing: type(of: root))
            } else {
                sessionTableKey = String(describing: type(of: viewController))
            }
        }
        if let existingSession = weakSessionTable.object(forKey: sessionTableKey as NSString) {
            weakSessionTable.removeObject(forKey: sessionTableKey as NSString)
            UIApplication.shared.requestSceneSessionDestruction(existingSession, options: nil) { _ in }
        }
        let activity = NSUserActivity(activityType: Self.activityType)
        let id = UUID()
        let info: [String: Any] = [idKey: id, widthKey: preferredSize.width, heightKey: preferredSize.height, sessionKey: sessionTableKey, titleVisibleKey: titleVisible, customToolbarKey: customToolbar]
        activity.userInfo = info
        viewControllersToPresent[id] = viewController
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { _ in }
    }
}
#endif
