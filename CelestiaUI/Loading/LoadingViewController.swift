// LoadingViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

public class LoadingViewController: UIViewController {
    private enum Constants {
        static let loadingGapVertical: CGFloat = 24
    }

    private let assetProvider: AssetProvider
    private var statusLabel = UILabel(textStyle: .body)

    public init(assetProvider: AssetProvider) {
        self.assetProvider = assetProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        view = UIView()
        #if !os(visionOS)
        view.backgroundColor = .systemBackground
        #endif
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

extension LoadingViewController {
    public func update(with status: String) {
        statusLabel.text = status
    }
}

private extension LoadingViewController {
    func setUp() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // display an icon above status
        let iconImageView = UIImageView(image: assetProvider.image(for: .loadingIcon))
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
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textColor = .label
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: Constants.loadingGapVertical),
            statusLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
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
            container.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
        ])

        let optionalConstraint = container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: GlobalConstants.pageMediumGapHorizontal)
        optionalConstraint.priority = .defaultLow
        optionalConstraint.isActive = true
    }
}
