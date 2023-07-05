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

import CelestiaCore
import CelestiaUI
import UIKit

class DestinationDetailViewController: UIViewController {
    private let destination: Destination
    private let goToHandler: () -> Void

    private lazy var scrollView = UIScrollView(frame: .zero)
    private lazy var goToButton = ActionButtonHelper.newButton()

    private lazy var descriptionLabel = UILabel(textStyle: .body)

    private lazy var contentStack = UIStackView(arrangedSubviews: [
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
        view.backgroundColor = .systemBackground

        setup()
    }

    @objc private func goToButtonClicked() {
        goToHandler()
    }
}

private extension DestinationDetailViewController {
    func setup() {
        title = destination.name

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
            contentContainer.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: GlobalConstants.pageMediumMarginVertical),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageMediumGapVertical),
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        contentContainer.backgroundColor = .clear

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = GlobalConstants.pageMediumGapVertical

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
        ])

        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byCharWrapping

        goToButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(goToButton)

        NSLayoutConstraint.activate([
            goToButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor),
            goToButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageMediumMarginVertical),
            goToButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            goToButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal),
        ])
        goToButton.addTarget(self, action: #selector(goToButtonClicked), for: .touchUpInside)

        descriptionLabel.text = destination.content
        goToButton.setTitle(CelestiaString("Go", comment: ""), for: .normal)
    }
}
