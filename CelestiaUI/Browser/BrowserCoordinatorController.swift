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

import CelestiaCore
import UIKit

class BrowserCoordinatorController: UINavigationController {
    private let item: BrowserItem

    private let selection: (Selection) -> UIViewController

    var viewControllerPushed: ((UINavigationController, UIViewController) -> Void)?

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
                let vc = self.create(for: sel)
                self.pushViewController(vc, animated: true)
                self.viewControllerPushed?(self, vc)
                return
            }
            guard let transformed = Selection(item: sel) else {
                self.showError(CelestiaString("Object not found", comment: ""))
                return
            }
            let vc = self.selection(transformed)
            self.pushViewController(vc, animated: true)
            self.viewControllerPushed?(self, vc)
        })
    }
}

#if targetEnvironment(macCatalyst)
@available(macCatalyst 16.0, *)
extension BrowserCoordinatorController: UINavigationBarDelegate {
    func navigationBarNSToolbarSection(_ navigationBar: UINavigationBar) -> UINavigationBar.NSToolbarSection {
        return .content
    }
}
#endif
