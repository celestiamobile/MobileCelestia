//
//  LoadingViewController.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/23.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController {

    private var statusLabel = UILabel()

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

extension LoadingViewController {
    func update(with status: String) {
        statusLabel.text = String(format: CelestiaString("Loading: %s", comment: "").toLocalizationTemplate, status)
    }
}

private extension LoadingViewController {
    func setup() {
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
        statusLabel.textColor = .darkLabel
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
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
