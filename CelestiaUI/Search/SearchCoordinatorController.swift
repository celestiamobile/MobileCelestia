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

import CelestiaCore
import UIKit

public class SearchCoordinatorController: UIViewController {
    private var main: SearchViewController!

    #if targetEnvironment(macCatalyst)
    private var split: UISplitViewController!
    #else
    private var navigation: UINavigationController!
    #endif

    private let executor: AsyncProviderExecutor

    private let selection: (Selection, Bool) -> UIViewController

    public init(executor: AsyncProviderExecutor, selected: @escaping (Selection, Bool) -> UIViewController) {
        self.selection = selected
        self.executor = executor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension SearchCoordinatorController {
    func setUp() {
        #if targetEnvironment(macCatalyst)
        let resultsInSidebar = true
        #else
        let resultsInSidebar = false
        #endif
        main = SearchViewController(resultsInSidebar: resultsInSidebar, executor: executor) { [unowned self] name in
            Task {
                let object = await self.executor.get {
                    $0.simulation.findObject(from: name)
                }
                guard !object.isEmpty else {
                    self.showError(CelestiaString("Object not found", comment: ""))
                    return
                }
                #if targetEnvironment(macCatalyst)
                self.split.viewControllers = [self.split.viewControllers[0], self.selection(object, false)]
                #else
                self.navigation.pushViewController(self.selection(object, true), animated: true)
                #endif
            }
        }

        #if targetEnvironment(macCatalyst)
        split = UISplitViewController()
        split.primaryBackgroundStyle = .sidebar
        split.preferredDisplayMode = .oneBesideSecondary
        split.preferredPrimaryColumnWidthFraction = 0.3
        let emptyVc = UIViewController()
        emptyVc.view.backgroundColor = .systemBackground
        split.viewControllers = [UINavigationController(rootViewController: main), emptyVc]
        install(split)
        #else
        navigation = UINavigationController(rootViewController: main)
        install(navigation)
        #endif
    }
}