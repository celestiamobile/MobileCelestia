//
// BrowserCoordinatorController.swift
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

class BrowserCoordinatorController: UIViewController {

    private var navigation: UINavigationController!

    private let item: CelestiaBrowserItem

    private let selection: (CelestiaSelection) -> UIViewController

    init(item: CelestiaBrowserItem, image: UIImage, selection: @escaping (CelestiaSelection) -> UIViewController) {
        self.item = item
        self.selection = selection
        super.init(nibName: nil, bundle: nil)

        tabBarItem = UITabBarItem(title: item.alternativeName ?? item.name, image: image, selectedImage: nil)
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

}

private extension BrowserCoordinatorController {
    func setup() {
        navigation = UINavigationController(rootViewController: create(for: item))

        install(navigation)

        if #available(iOS 13.0, *) {
        } else {
            navigation.navigationBar.barStyle = .black
            navigation.navigationBar.barTintColor = .darkBackground
            navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
        }
    }

    func create(for item: CelestiaBrowserItem) -> BrowserCommonViewController {
        return BrowserCommonViewController(item: item, selection: { [unowned self] (sel, finish) in
            if !finish {
                self.navigation.pushViewController(self.create(for: sel), animated: true)
                return
            }
            guard let transformed = CelestiaSelection(item: sel) else {
                self.showError(CelestiaString("Object not found", comment: ""))
                return
            }
            self.navigation.pushViewController(self.selection(transformed), animated: true)
        })
    }
}

