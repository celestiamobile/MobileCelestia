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
        view.backgroundColor = .darkBackground
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

            switch item.type {
            case .multiSelection:
                if let associated = item.associatedItem.base as? AssociatedMultiSelectionItem {
                    let controller = SettingCheckViewController(item: SettingCheckViewController.Item(title: item.name, masterKey: associated.masterKey, subitems: associated.items))
                    self.navigation.pushViewController(controller, animated: true)
                } else {
                    logWrongAssociatedItemType(item.associatedItem)
                }
            case .selection:
                if let associated = item.associatedItem.base as? AssociatedSelectionItem {
                    let controller = SettingSelectionViewController(item: SettingSelectionViewController.Item(title: item.name, key: associated.key, subitems: associated.items))
                    self.navigation.pushViewController(controller, animated: true)
                } else {
                    logWrongAssociatedItemType(item.associatedItem)
                }
            case .common:
                if let associated = item.associatedItem.base as? AssociatedCommonItem {
                    let controller = SettingCommonViewController(item: associated)
                    self.navigation.pushViewController(controller, animated: true)
                } else {
                    logWrongAssociatedItemType(item.associatedItem)
                }
            case .about:
                self.navigation.pushViewController(AboutViewController(), animated: true)
            case .time:
                self.navigation.pushViewController(TimeSettingViewController(), animated: true)
            case .render:
                self.navigation.pushViewController(TextViewController(title: item.name, text: renderInfo), animated: true)
            case .dataLocation:
                self.navigation.pushViewController(DataLocationSelectionViewController(), animated: true)
            case .slider, .prefSwitch, .checkmark, .action, .custom:
                fatalError("Use .common for slider/action setting item.")
            }
        })
        navigation = UINavigationController(rootViewController: main)

        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.barTintColor = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }
}
