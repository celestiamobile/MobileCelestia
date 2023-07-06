//
// GoToContainerViewController.swift
//
// Copyright © 2021 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

public class GoToContainerViewController: UINavigationController {
    public init(
        executor: AsyncProviderExecutor,
        locationHandler: @escaping ((GoToLocation) -> Void),
        textInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ text: String, _ keyboardType: UIKeyboardType) async -> String?
    ) {
        super.init(rootViewController: UIViewController())

        setViewControllers([
            GoToInputViewController(executor: executor, objectNameHandler: { [weak self] controller in
                guard let self else { return }
                let searchController = SearchViewController(resultsInSidebar: false, executor: executor) { [weak self, weak controller] name in
                    guard let self else { return }
                    guard let controller = controller else { return }
                    self.popViewController(animated: true)
                    controller.updateObjectName(name)
                }
                self.pushViewController(searchController, animated: true)
            }, locationHandler: { location in
                locationHandler(location)
            }, textInputHandler: textInputHandler)
        ], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
