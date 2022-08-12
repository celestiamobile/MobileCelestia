//
// DestinationDetailViewController.swift
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

class DestinationDetailViewController: UIViewController {
    private let destination: Destination
    private let goToHandler: () -> Void

    private lazy var scrollView = UIScrollView(frame: .zero)
    private lazy var goToButton = ActionButtonHelper.newButton()

    private lazy var titleLabel = UILabel(textStyle: .title2, weight: .semibold)
    private lazy var descriptionLabel = UILabel(textStyle: .body)

    private lazy var contentStack = UIStackView(arrangedSubviews: [
        titleLabel,
        descriptionLabel,
    ])

    init(destination: Destination, goToHandler: @escaping () -> Void) {
        self.destination = destination
        self.goToHandler = goToHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground

        setup()
    }

    @objc private func goToButtonClicked() {
        goToHandler()
    }
}

private extension DestinationDetailViewController {
    func setup() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentContainer)
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: GlobalConstants.pageMarginVertical),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageGapVertical),
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: GlobalConstants.pageMarginHorizontal),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -GlobalConstants.pageMarginHorizontal),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        contentContainer.backgroundColor = .clear

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = GlobalConstants.pageGapVertical

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
        ])

        titleLabel.textColor = .darkLabel
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byCharWrapping

        descriptionLabel.textColor = .darkSecondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byCharWrapping

        goToButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(goToButton)

        NSLayoutConstraint.activate([
            goToButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor),
            goToButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageMarginVertical),
            goToButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: GlobalConstants.pageMarginHorizontal),
            goToButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -GlobalConstants.pageMarginHorizontal),
        ])
        goToButton.addTarget(self, action: #selector(goToButtonClicked), for: .touchUpInside)

        titleLabel.text = destination.name
        descriptionLabel.text = destination.content
        goToButton.setTitle(CelestiaString("Go", comment: ""), for: .normal)
    }
}
