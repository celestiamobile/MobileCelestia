//
// LoadingViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public class LoadingViewController: UIViewController {
    private enum Constants {
        static let loadingGapVertical: CGFloat = 24
    }

    private var statusLabel = UILabel(textStyle: .body)

    public override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

extension LoadingViewController {
    public func update(with status: String) {
        statusLabel.text = String.localizedStringWithFormat(CelestiaString("Loading: %@", comment: ""), status)
    }
}

private extension LoadingViewController {
    func setUp() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // display an icon above status
        let iconImageView = UIImageView(image: #imageLiteral(resourceName: "loading_icon"))
        container.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: container.topAnchor),
            iconImageView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
            iconImageView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
        ])

        // status label
        container.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textColor = .label
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: Constants.loadingGapVertical),
            statusLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let labelWidthConstraints = [
            statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ]
        labelWidthConstraints.forEach { $0.priority = .defaultLow }
        NSLayoutConstraint.activate(labelWidthConstraints)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
