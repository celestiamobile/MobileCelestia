// DestinationDetailViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

class DestinationDetailViewController: UIViewController {
    private let destination: Destination
    private let goToHandler: () -> Void

    private lazy var scrollView = UIScrollView(frame: .zero)
    private lazy var goToButton: UIButton = {
        if #available(iOS 26, *), traitCollection.userInterfaceIdiom != .mac {
            return UIButton(configuration: .glass())
        }
        return ActionButtonHelper.newButton()
    }()

    private lazy var descriptionLabel = UITextView()

    private lazy var contentStack = UIStackView(arrangedSubviews: [
        descriptionLabel,
    ])

    private var bottomButtonContainerBoundsObservation: NSKeyValueObservation?

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
        #if !os(visionOS)
        view.backgroundColor = .systemBackground
        #endif

        setup()
    }

    @objc private func goToButtonClicked() {
        goToHandler()
    }
}

private extension DestinationDetailViewController {
    func setup() {
        title = destination.name
        windowTitle = title

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentContainer)
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: GlobalConstants.pageMediumMarginVertical),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageMediumGapVertical),
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.trailingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal),
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

        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.backgroundColor = .clear
        descriptionLabel.textContainer.maximumNumberOfLines = 0
        descriptionLabel.textContainerInset = UIEdgeInsets(top: 0, left: -descriptionLabel.textContainer.lineFragmentPadding, bottom: 0, right: -descriptionLabel.textContainer.lineFragmentPadding)
        descriptionLabel.isScrollEnabled = false
        descriptionLabel.isEditable = false
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.textContainer.lineBreakMode = .byWordWrapping

        goToButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(goToButton)

        NSLayoutConstraint.activate([
            goToButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageMediumMarginVertical),
            goToButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            goToButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal),
        ])
        goToButton.addTarget(self, action: #selector(goToButtonClicked), for: .touchUpInside)

        descriptionLabel.text = destination.content
        goToButton.setTitle(CelestiaString("Go", comment: "Go to an object"), for: .normal)

        if #available(iOS 26, *), traitCollection.userInterfaceIdiom != .mac {
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            bottomButtonContainerBoundsObservation = goToButton.observe(\.bounds, options: [.initial, .new], changeHandler: { [weak self] _, _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.scrollView.contentInset.bottom = self.goToButton.bounds.height + GlobalConstants.pageMediumMarginVertical * 2
                }
            })
            let edgeInteraction = UIScrollEdgeElementContainerInteraction()
            edgeInteraction.scrollView = scrollView
            edgeInteraction.edge = .bottom
            goToButton.addInteraction(edgeInteraction)
        } else {
            goToButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        }
    }
}
