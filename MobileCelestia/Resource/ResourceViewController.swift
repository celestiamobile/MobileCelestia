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
    #if targetEnvironment(macCatalyst)
    private lazy var controller = UISplitViewController()
    #endif
    private var main: ResourceCategoryListViewController!
    private var navigation: UINavigationController!

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackgroundElevated
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

    private func viewCategory(_ category: ResourceCategory) {
        let vc = ResourceItemListViewController(category: category) { [weak self] item in
            self?.viewItem(item)
        }
        #if targetEnvironment(macCatalyst)
        navigation = UINavigationController(rootViewController: vc)
        if #available(iOS 13.0, *) {
        } else {
            navigation.navigationBar.barStyle = .black
            navigation.navigationBar.barTintColor = .darkBackgroundElevated
            navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
        }
        controller.viewControllers = [controller.viewControllers[0], navigation]
        #else
        navigation.pushViewController(vc, animated: true)
        #endif
    }

    private func viewItem(_ item: ResourceItem) {
        navigation.pushViewController(ResourceItemViewController(item: item), animated: true)
    }

    private func viewInstalled() {
        let vc = InstalledResourceViewController { [weak self] item in
            self?.viewItem(item)
        }
        #if targetEnvironment(macCatalyst)
        navigation = UINavigationController(rootViewController: vc)
        if #available(iOS 13.0, *) {
        } else {
            navigation.navigationBar.barStyle = .black
            navigation.navigationBar.barTintColor = .darkBackgroundElevated
            navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
        }
        controller.viewControllers = [controller.viewControllers[0], navigation]
        #else
        navigation.pushViewController(vc, animated: true)
        #endif
    }
}
