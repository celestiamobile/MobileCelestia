//
// EventFinderCoordinatorViewController.swift
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

class EventFinderCoordinatorViewController: UINavigationController {
    private let eventHandler: ((Eclipse) -> Void)

    init(eventHandler: @escaping ((Eclipse) -> Void)) {
        self.eventHandler = eventHandler
        super.init(rootViewController: UIViewController())
        setViewControllers([EventFinderInputViewController() { [weak self] results in
            guard let self else { return }
            self.pushViewController(EventFinderResultViewController(results: results, eventHandler: { (eclipse) in
                self.eventHandler(eclipse)
            }), animated: true)
        }], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

