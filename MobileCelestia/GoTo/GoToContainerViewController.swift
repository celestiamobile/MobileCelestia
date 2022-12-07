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

class GoToContainerViewController: UINavigationController {
    private let locationHandler: ((GoToLocation) -> Void)

    init(locationHandler: @escaping ((GoToLocation) -> Void)) {
        self.locationHandler = locationHandler
        super.init(rootViewController: UIViewController())

        setViewControllers([
            GoToInputViewController(objectNameHandler: { [weak self] controller in
                guard let self else { return }
                let searchController = SearchViewController(resultsInSidebar: false) { [weak self, weak controller] name in
                    guard let self else { return }
                    guard let controller = controller else { return }
                    self.popViewController(animated: true)
                    controller.updateObjectName(name)
                }
                self.pushViewController(searchController, animated: true)
            }) { [weak self] location in
                guard let self = self else { return }
                self.locationHandler(location)
            }
        ], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
