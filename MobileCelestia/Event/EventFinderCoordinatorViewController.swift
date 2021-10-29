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

class EventFinderCoordinatorViewController: UIViewController {
    private var navigation: UINavigationController!

    private let eventHandler: ((Eclipse) -> Void)

    init(eventHandler: @escaping ((Eclipse) -> Void)) {
        self.eventHandler = eventHandler
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

private extension EventFinderCoordinatorViewController {
    func setup() {
        navigation = UINavigationController(rootViewController: EventFinderInputViewController { [weak self] results in
            guard let self = self else { return }
            self.navigation.pushViewController(EventFinderResultViewController(results: results, eventHandler: { (eclipse) in
                self.eventHandler(eclipse)
            }), animated: true)
        })

        install(navigation)

        if #available(iOS 13.0, *) {
        } else {
            navigation.navigationBar.barStyle = .black
            navigation.navigationBar.barTintColor = .darkBackground
            navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
        }
    }
}


