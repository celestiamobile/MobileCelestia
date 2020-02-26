//
//  SettingsCoordinatorController.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class SettingsCoordinatorController: UIViewController {

    private var main: SettingsMainViewController!
    private var navigation: UINavigationController!

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

private extension SettingsCoordinatorController {
    func setup() {
        main = SettingsMainViewController(selection: { [unowned self] (item) in
            switch item.type {
            case .checkmarks(let masterKey, let items):
                let controller = SettingCheckViewController(item: SettingCheckViewController.Item(title: item.name, masterKey: masterKey, subitems: items))
                self.navigation.pushViewController(controller, animated: true)
            case .selection(let key, let items):
                let controller = SettingSelectionViewController(item: SettingSelectionViewController.Item(title: item.name, key: key, subitems: items))
                self.navigation.pushViewController(controller, animated: true)
            case .about:
                self.navigation.pushViewController(AboutViewController(), animated: true)
            case .time:
                self.navigation.pushViewController(TimeSettingViewController(), animated: true)
            case .render:
                self.navigation.pushViewController(TextViewController(title: item.name, text: renderInfo), animated: true)
            }
        })
        navigation = UINavigationController(rootViewController: main)

        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }
}
