//
// OnboardViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

enum OnboardAction {
    case tutorial(action: TutorialAction)
}

class OnboardViewController: UIViewController {

    private let actionHandler: ((OnboardAction) -> Void)

    init(actionHandler: @escaping ((OnboardAction) -> Void)) {
        self.actionHandler = actionHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension OnboardViewController {
    func setup() {
        view.backgroundColor = .darkSecondaryBackground

        let welcomeView = UILabel()
        welcomeView.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        welcomeView.text = CelestiaString("Welcome to Celestia", comment: "")
        welcomeView.textColor = .darkLabel
        welcomeView.numberOfLines = 0
        welcomeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomeView)

        NSLayoutConstraint.activate([
            welcomeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            welcomeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            welcomeView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
        ])

        let tutorialController = TutorialViewController { [unowned self] (action) in
            self.actionHandler(.tutorial(action: action))
        }

        // add child vc
        addChild(tutorialController)

        tutorialController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tutorialController.view)

        NSLayoutConstraint.activate([
            tutorialController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tutorialController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tutorialController.view.topAnchor.constraint(equalTo: welcomeView.bottomAnchor, constant: 16),
            tutorialController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tutorialController.didMove(toParent: self)
    }
}
