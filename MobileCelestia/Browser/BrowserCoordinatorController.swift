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

class BrowserCoordinatorController: UINavigationController {
    private let item: BrowserItem

    private let selection: (Selection) -> UIViewController

    init(item: BrowserItem, image: UIImage, selection: @escaping (Selection) -> UIViewController) {
        self.item = item
        self.selection = selection
        super.init(rootViewController: UIViewController())

        tabBarItem = UITabBarItem(title: item.alternativeName ?? item.name, image: image, selectedImage: nil)

        setViewControllers([create(for: item)], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension BrowserCoordinatorController {
    func create(for item: BrowserItem) -> BrowserCommonViewController {
        return BrowserCommonViewController(item: item, selection: { [weak self] (sel, finish) in
            guard let self else { return }
            if !finish {
                self.pushViewController(self.create(for: sel), animated: true)
                return
            }
            guard let transformed = Selection(item: sel) else {
                self.showError(CelestiaString("Object not found", comment: ""))
                return
            }
            self.pushViewController(self.selection(transformed), animated: true)
        })
    }
}

