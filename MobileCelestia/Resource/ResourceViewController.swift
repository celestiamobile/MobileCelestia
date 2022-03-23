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
        let vc = InstalledResourceViewController { [weak self] item in
            self?.viewItem(item)
        }
        navigation = UINavigationController(rootViewController: vc)
        install(navigation)
    }

    private func viewItem(_ item: ResourceItem) {
        navigation.pushViewController(ResourceItemViewController(item: item), animated: true)
    }
}
