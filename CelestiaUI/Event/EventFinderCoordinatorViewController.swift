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

import CelestiaCore
import UIKit

public class EventFinderCoordinatorViewController: UINavigationController {
    public init(
        executor: AsyncProviderExecutor,
        eventHandler: @escaping ((Eclipse) -> Void),
        textInputHandler: @escaping (_ viewController: UIViewController, _ title: String) async -> String?,
        dateInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?
    ) {
        super.init(rootViewController: UIViewController())
        setViewControllers([EventFinderInputViewController(executor: executor, resultHandler: { [weak self] results in
            guard let self else { return }
            self.pushViewController(EventFinderResultViewController(results: results, eventHandler: eventHandler), animated: true)
        }, textInputHandler: textInputHandler, dateInputHandler: dateInputHandler)], animated: false)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

