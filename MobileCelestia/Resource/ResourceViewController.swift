//
// ResourceViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class ResourceViewController: UIViewController {
    private var main: ResourceCategoryListViewController!
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

private extension ResourceViewController {
    func setup() {
        main = ResourceCategoryListViewController(selection: { [weak self] category in
            guard let self = self else { return }
            switch category {
            case .installed:
                self.viewInstalled()
            case .wrapped(let category):
                self.viewCategory(category)
            }
        }) { [weak self] in
            self?.viewInstalled()
        }
        navigation = UINavigationController(rootViewController: main)

        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.barTintColor = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }

    private func viewCategory(_ category: ResourceCategory) {
        navigation.pushViewController(ResourceItemListViewController(category: category) { [weak self] item in
            self?.viewItem(item)
        }, animated: true)
    }

    private func viewItem(_ item: ResourceItem) {
        navigation.pushViewController(ResourceItemViewController(item: item), animated: true)
    }

    private func viewInstalled() {
        navigation.pushViewController(InstalledResourceViewController { [weak self] item in
            self?.viewItem(item)
        }, animated: true)
    }
}
