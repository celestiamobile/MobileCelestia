//
//  SettingsCoordinatorController.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class SettingsCoordinatorController: UIViewController {

    private lazy var main = SettingsMainViewController()
    private lazy var navigation = UINavigationController(rootViewController: self.main)

    override var preferredContentSize: CGSize {
        set {}
        get { return CGSize(width: 300, height: 300) }
    }

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
        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }
}
