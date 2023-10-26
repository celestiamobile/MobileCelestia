//
// SubscriptionBackingViewController.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

@available(iOS 15, *)
open class SubscriptionBackingViewController: UIViewController {
    let subscriptionManager: SubscriptionManager
    let viewControllerBuilder: () async -> UIViewController
    let openSubscriptionManagement: () -> Void

    private lazy var loadingView = UIActivityIndicatorView(style: .large)

    private lazy var emptyHintView: UIView = {
        let label = UILabel(textStyle: .body)
        label.text = CelestiaString("This feature is only available to Celestia PLUS users.", comment: "")
        label.numberOfLines = 0
        label.textAlignment = .center
        let button = ActionButtonHelper.newButton()
        button.setTitle(CelestiaString("Get Celestia PLUS", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(requestOpenSubscriptionManagement), for: .touchUpInside)
        label.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        let view = UIView()
        view.addSubview(label)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: GlobalConstants.pageMediumGapVertical),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            button.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
        ])
        let optionalConstraints = [
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        ]
        for constraint in optionalConstraints {
            constraint.priority = .defaultLow
        }
        NSLayoutConstraint.activate(optionalConstraints)
        return view
    }()

    init(
        subscriptionManager: SubscriptionManager,
        openSubscriptionManagement: @escaping () -> Void,
        viewControllerBuilder: @escaping () async -> UIViewController
    ) {
        self.subscriptionManager = subscriptionManager
        self.openSubscriptionManagement = openSubscriptionManagement
        self.viewControllerBuilder = viewControllerBuilder
        super.init(nibName: nil, bundle: nil)
    }

    open override func loadView() {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground

        containerView.addSubview(emptyHintView)
        containerView.addSubview(loadingView)

        emptyHintView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            emptyHintView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emptyHintView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            emptyHintView.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor),
        ])

        emptyHintView.isHidden = true

        view = containerView
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        loadingView.startAnimating()

        Task {
            let transactionInfo = subscriptionManager.transactionInfo()
            if transactionInfo == nil {
                loadingView.stopAnimating()
                loadingView.isHidden = true
                emptyHintView.isHidden = false
            } else {
                let viewController = await viewControllerBuilder()
                loadingView.stopAnimating()
                loadingView.isHidden = true
                install(viewController)
                view.sendSubviewToBack(viewController.view)
            }
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func requestOpenSubscriptionManagement() {
        openSubscriptionManagement()
    }
}
