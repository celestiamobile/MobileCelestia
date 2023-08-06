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

public class SearchCoordinatorController: ToolbarNavigationContainerController {
    private let executor: AsyncProviderExecutor

    private let selection: (Selection) -> UIViewController

    public init(executor: AsyncProviderExecutor, selected: @escaping (Selection) -> UIViewController) {
        self.selection = selected
        self.executor = executor
        super.init(rootViewController: UIViewController())
        setViewControllers([SearchViewController(resultsInSidebar: false, executor: executor) { [weak self] name in
            guard let self else { return }
            Task {
                let object = await self.executor.get {
                    $0.simulation.findObject(from: name)
                }
                guard !object.isEmpty else {
                    self.showError(CelestiaString("Object not found", comment: ""))
                    return
                }
                let viewController = self.selection(object)
                self.pushViewController(viewController, animated: true)
            }
        }], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
