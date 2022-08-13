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
    case url(url: URL)
}

class OnboardViewController: UIViewController {

    private let actionHandler: ((OnboardAction) -> Void)
    private let urlHandler: (())

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

        let welcomeView = UILabel(textStyle: .largeTitle)
        welcomeView.text = CelestiaString("Welcome to Celestia", comment: "")
        welcomeView.textColor = .darkLabel
        welcomeView.numberOfLines = 0
        welcomeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomeView)

        NSLayoutConstraint.activate([
            welcomeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            welcomeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal),
            welcomeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: GlobalConstants.pageMediumMarginVertical),
        ])

        let tutorialController = TutorialViewController(actionHandler: { [unowned self] (action) in
            self.actionHandler(.tutorial(action: action))
        }, urlHandler: { url in
            self.actionHandler(.url(url: url))
        })

        // add child vc
        addChild(tutorialController)

        tutorialController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tutorialController.view)

        NSLayoutConstraint.activate([
            tutorialController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tutorialController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tutorialController.view.topAnchor.constraint(equalTo: welcomeView.bottomAnchor, constant: GlobalConstants.pageMediumGapVertical),
            tutorialController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tutorialController.didMove(toParent: self)
    }
}
