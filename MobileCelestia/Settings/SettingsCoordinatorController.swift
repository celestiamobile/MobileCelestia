//
// SettingsCoordinatorController.swift
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

enum SettingAction {
}

class SettingsCoordinatorController: UIViewController {
    #if targetEnvironment(macCatalyst)
    private lazy var controller = UISplitViewController()
    #endif
    private var main: SettingsMainViewController!
    private var navigation: UINavigationController!

    private let actionHandler: ((SettingAction) -> Void)

    init(actionHandler: @escaping ((SettingAction) -> Void)) {
        self.actionHandler = actionHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackgroundElevated
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        CelestiaAppCore.shared.storeUserDefaults()
    }
}

private extension SettingsCoordinatorController {
    func setup() {
        main = SettingsMainViewController(selection: { [unowned self] (item) in
            func logWrongAssociatedItemType(_ item: AnyHashable) -> Never {
                fatalError("Wrong associated item \(item.base)")
            }

            let viewController: UIViewController
            switch item.type {
            case .multiSelection:
                if let associated = item.associatedItem.base as? AssociatedMultiSelectionItem {
                    viewController = SettingCheckViewController(item: SettingCheckViewController.Item(title: item.name, masterKey: associated.masterKey, subitems: associated.items))
                } else {
                    logWrongAssociatedItemType(item.associatedItem)
                }
            case .selection:
                if let associated = item.associatedItem.base as? AssociatedSelectionItem {
                    viewController = SettingSelectionViewController(item: SettingSelectionViewController.Item(title: item.name, key: associated.key, subitems: associated.items))
                } else {
                    logWrongAssociatedItemType(item.associatedItem)
                }
            case .common:
                if let associated = item.associatedItem.base as? AssociatedCommonItem {
                    viewController = SettingCommonViewController(item: associated)
                } else {
                    logWrongAssociatedItemType(item.associatedItem)
                }
            case .about:
                viewController = AboutViewController()
            case .time:
                viewController = TimeSettingViewController()
            case .render:
                viewController = TextViewController(title: item.name, text: renderInfo)
            case .dataLocation:
                viewController = DataLocationSelectionViewController()
            case .slider, .prefSwitch, .checkmark, .action, .custom:
                fatalError("Use .common for slider/action setting item.")
            }
            #if targetEnvironment(macCatalyst)
            self.navigation = UINavigationController(rootViewController: viewController)
            if #available(iOS 13.0, *) {
            } else {
                self.navigation.navigationBar.barStyle = .black
                self.navigation.navigationBar.barTintColor = .darkBackgroundElevated
                self.navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
            }
            self.controller.viewControllers = [self.controller.viewControllers[0], self.navigation]
            #else
            self.navigation.pushViewController(viewController, animated: true)
            #endif
        })
        #if targetEnvironment(macCatalyst)
        controller.primaryBackgroundStyle = .sidebar
        controller.preferredDisplayMode = .oneBesideSecondary
        controller.preferredPrimaryColumnWidthFraction = 0.3
        let emptyVc = UIViewController()
        emptyVc.view.backgroundColor = .darkBackgroundElevated
        controller.viewControllers = [main, emptyVc]
        install(controller)
        #else
        navigation = UINavigationController(rootViewController: main)
        install(navigation)
        if #available(iOS 13.0, *) {
        } else {
            navigation.navigationBar.barStyle = .black
            navigation.navigationBar.barTintColor = .darkBackgroundElevated
            navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
        }
        #endif
    }
}
