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

import UIKit

#if targetEnvironment(macCatalyst)
@available(iOS 13, *)
class PanelSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        guard let userInfo = connectionOptions.userActivities.first?.userInfo else { return }
        guard let id = userInfo[Self.idKey] as? UUID, let width = userInfo[Self.widthKey] as? CGFloat, let height = userInfo[Self.heightKey] as? CGFloat else { return }
        guard let viewController = Self.viewControllersToPresent.removeValue(forKey: id) else { return }
        let size = CGSize(width: width, height: height)
        Self.weakSessionTable.setObject(session, forKey: String(describing: type(of: viewController)) as NSString)

        windowScene.titlebar?.titleVisibility = .hidden
        windowScene.sizeRestrictions?.minimumSize = size
        windowScene.sizeRestrictions?.maximumSize = size
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        window.rootViewController = viewController

        self.window = window
        window.makeKeyAndVisible()

        NotificationCenter.default.addObserver(self, selector: #selector(handleNSWindowDidBecomeKey(_:)), name: NSNotification.Name("NSWindowDidBecomeKeyNotification"), object: nil)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleNSWindowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSObject else { return }
        guard window == self.window?.nsWindow else { return }
        MacBridge.disableFullScreenForNSWindow(window)
    }

    static var activityType = "\(Bundle.main.bundleIdentifier!).Panel"
    private static var idKey = "id"
    private static var widthKey = "width"
    private static var heightKey = "height"
    private static var viewControllersToPresent: [UUID : UIViewController] = [:]
    private static var weakSessionTable = NSMapTable<NSString, UISceneSession>(keyOptions: .strongMemory, valueOptions: .weakMemory)

    static func present(_ viewController: UIViewController, preferredSize: CGSize) {
        if let existingSession = weakSessionTable.object(forKey: String(describing: type(of: viewController)) as NSString) {
            UIApplication.shared.requestSceneSessionDestruction(existingSession, options: nil) { _ in }
        }
        let activity = NSUserActivity(activityType: "\(Bundle.main.bundleIdentifier!).Panel")
        let id = UUID()
        activity.userInfo = [idKey : id, widthKey : preferredSize.width, heightKey : preferredSize.height]
        viewControllersToPresent[id] = viewController
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { _ in }
    }
}

fileprivate extension UIWindow {
    var nsWindow: NSObject? {
        return MacBridge.nsWindowForUIWindow(self)
    }
}
#endif
