//
// MainSceneDelegate.swift
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
import UIKit

class MainSceneDelegate: CommonSceneDelegate {
    var window: UIWindow?

    static var mainWindowSessionIdentifier: String?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        if Self.mainWindowSessionIdentifier != nil {
            let window = UIWindow(windowScene: windowScene)
            window.overrideUserInterfaceStyle = .dark
            window.rootViewController = UnsupportedViewController()
            self.window = window
            window.makeKeyAndVisible()
            return
        }

        Self.mainWindowSessionIdentifier = scene.session.persistentIdentifier

        #if targetEnvironment(macCatalyst)
        windowScene.titlebar?.autoHidesToolbarInFullScreen = true
        #endif
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        var launchURL: UniformedURL?
        if let url = connectionOptions.urlContexts.first {
            launchURL = UniformedURL(url: url.url, securityScoped: url.url.isFileURL && url.options.openInPlace)
        }
        let vc = MainViewController(initialURL: launchURL, screen: windowScene.screen)
        #if targetEnvironment(macCatalyst)
        let toolbar = NSToolbar(identifier: UUID().uuidString)
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        windowScene.titlebar?.toolbar = toolbar
        vc.nsToolbar = toolbar
        #endif
        window.rootViewController = vc

        self.window = window
        window.makeKeyAndVisible()

        if let userActivity = connectionOptions.userActivities.first {
            // Delay this so the view gets loaded before user activity gets handled
            Task {
                try await Task.sleep(nanoseconds: 500000000)
                AppDelegate.handleUserActivity(userActivity)
            }
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        let application = UIApplication.shared
        let backgroundTaskID = application.beginBackgroundTask(expirationHandler: nil)
        if backgroundTaskID == .invalid {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            application.endBackgroundTask(backgroundTaskID)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if scene.session.persistentIdentifier != Self.mainWindowSessionIdentifier {
            return
        }
        exit(0)
    }

    // Temporary workaround for multiple windows
    class UnsupportedViewController: UIViewController {
        override func loadView() {
            let containerView = UIView()
            containerView.backgroundColor = .systemBackground
            let label = UILabel(textStyle: .body)
            label.numberOfLines = 0
            label.text = "Multiple Celestia windows within a single instance is supported, please send an e-mail to lilinfeng.app@outlook.com with reproduction steps."
            containerView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .label
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            ])
            view = containerView
        }
    }
}
