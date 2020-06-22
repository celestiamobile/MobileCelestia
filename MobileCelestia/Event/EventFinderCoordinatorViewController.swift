//
//  EventFinderCoordinatorViewController.swift
//  MobileCelestia
//
//  Created by Levin Li on 2020/6/22.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

class EventFinderCoordinatorViewController: UIViewController {

    private var main: SettingsMainViewController!
    private var navigation: UINavigationController!

    private let eventHandler: ((CelestiaEclipse) -> Void)

    init(eventHandler: @escaping ((CelestiaEclipse) -> Void)) {
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

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }
}


