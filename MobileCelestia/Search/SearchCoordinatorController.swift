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

    #if targetEnvironment(macCatalyst)
    private var split: UISplitViewController!
    #endif

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
        view.backgroundColor = .darkBackgroundElevated
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension SearchCoordinatorController {
    func setUp() {
        main = SearchViewController(selected: { [unowned self] (info) in
            #if targetEnvironment(macCatalyst)
            self.split.viewControllers = [navigation, self.selection(info)]
            #else
            self.navigation.pushViewController(self.selection(info), animated: true)
            #endif
        })
        navigation = UINavigationController(rootViewController: main)

        if #available(iOS 13.0, *) {
        } else {
            navigation.navigationBar.barStyle = .black
            navigation.navigationBar.barTintColor = .darkBackgroundElevated
            navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
        }

        #if targetEnvironment(macCatalyst)
        split = UISplitViewController()
        split.primaryBackgroundStyle = .sidebar
        split.preferredDisplayMode = .oneBesideSecondary
        split.preferredPrimaryColumnWidthFraction = 0.3
        let emptyVc = UIViewController()
        emptyVc.view.backgroundColor = .darkBackground
        split.viewControllers = [navigation, emptyVc]
        install(split)
        #else
        install(navigation)
        #endif
    }
}
