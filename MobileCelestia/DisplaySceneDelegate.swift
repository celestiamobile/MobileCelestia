//
// DisplaySceneDelegate.swift
//
// Copyright © 2021 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

#if targetEnvironment(macCatalyst)
class DisplaySceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    static var activityType = "\(Bundle.app.bundleIdentifier!).Display"
    static var displayWindowSessionIdentifier: String?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        if Self.displayWindowSessionIdentifier != nil {
            let window = UIWindow(windowScene: windowScene)
            window.overrideUserInterfaceStyle = .dark
            window.rootViewController = UnsupportedViewController()
            self.window = window
            window.makeKeyAndVisible()
            return
        }

        let allWindowScenes = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
        guard let mainSceneDelegate = allWindowScenes.compactMap({ $0.delegate as? MainSceneDelegate }).first else {
            fatalError("Main scene delegate not found")
        }

        guard let mainWindow = mainSceneDelegate.window else {
            fatalError("Main scene does not have a window")
        }

        guard let mainVC = mainWindow.rootViewController as? MainViewController else {
            fatalError("Main window does not contain MainVC")
        }

        Self.displayWindowSessionIdentifier = scene.session.persistentIdentifier

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        mainVC.celestiaController.moveToNewWindow(window)

        self.window = window
        window.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        AppDelegate.handleUserActivity(userActivity)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        guard scene.session.persistentIdentifier == Self.displayWindowSessionIdentifier else { return }

        Self.displayWindowSessionIdentifier = nil

        guard let win = window else { return }

        let allWindowScenes = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
        if let mainSceneDelegate = allWindowScenes.compactMap({ $0.delegate as? MainSceneDelegate }).first {
            if let mainWindow = mainSceneDelegate.window, let mainVC = mainWindow.rootViewController as? MainViewController {
                mainVC.celestiaController.moveBack(from: win)
            }
        }
    }

    // Temporary workaround for multiple windows
    class UnsupportedViewController: UIViewController {
        override func loadView() {
            let containerView = UIView()
            containerView.backgroundColor = .systemBackground
            let label = UILabel()
            label.numberOfLines = 0
            label.text = "Mirroring Celestia to multiple windows within a single instance is supported, please send an e-mail to lilinfeng.app@outlook.com with reproduction steps."
            containerView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .label
            label.font = UIFont.preferredFont(forTextStyle: .body)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 16),
            ])
            view = containerView
        }
    }
}
#endif
