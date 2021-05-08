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

class GoToContainerViewController: UIViewController {
    private var navigation: UINavigationController!

    private let locationHandler: ((CelestiaGoToLocation) -> Void)

    init(locationHandler: @escaping ((CelestiaGoToLocation) -> Void)) {
        self.locationHandler = locationHandler
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

        setup()
    }
}

private extension GoToContainerViewController {
    func setup() {
        navigation = UINavigationController(rootViewController: GoToInputViewController { [weak self] location in
            guard let self = self else { return }
            self.locationHandler(location)
        })

        install(navigation)

        if #available(iOS 13.0, *) {
        } else {
            navigation.navigationBar.barStyle = .black
            navigation.navigationBar.barTintColor = .darkBackgroundElevated
            navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
        }
    }
}
