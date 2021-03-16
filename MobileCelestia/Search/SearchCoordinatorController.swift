//
// SearchCoordinatorController.swift
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

class SearchCoordinatorController: UIViewController {
    private var main: SearchViewController!
    private var navigation: UINavigationController!

    private let selection: (CelestiaSelection) -> UIViewController

    init(selected: @escaping (CelestiaSelection) -> UIViewController) {
        self.selection = selected
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

}

private extension SearchCoordinatorController {
    func setup() {
        main = SearchViewController(selected: { [unowned self] (info) in
            self.navigation.pushViewController(self.selection(info), animated: true)
        })
        navigation = UINavigationController(rootViewController: main)

        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.barTintColor = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }
}
