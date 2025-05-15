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
    private let subscriptionManager: SubscriptionManager
    private let viewControllerBuilder: (SubscriptionBackingViewController) async -> UIViewController
    private let openSubscriptionManagement: () -> Void

    var currentViewController: UIViewController?

    private lazy var loadingView = UIActivityIndicatorView(style: .large)

    private lazy var emptyHintView: EmptyHintView = {
        let view = EmptyHintView()
        view.title = CelestiaString("This feature is only available to Celestia PLUS users.", comment: "")
        view.actionText = CelestiaString("Get Celestia PLUS", comment: "")
        view.action = { [weak self] in
            guard let self else { return }
            self.requestOpenSubscriptionManagement()
        }
        return view
    }()
    private lazy var emptyViewContainer = SafeAreaView(view: emptyHintView)

    init(
        subscriptionManager: SubscriptionManager,
        openSubscriptionManagement: @escaping () -> Void,
        viewControllerBuilder: @escaping (SubscriptionBackingViewController) async -> UIViewController
    ) {
        self.subscriptionManager = subscriptionManager
        self.openSubscriptionManagement = openSubscriptionManagement
        self.viewControllerBuilder = viewControllerBuilder
        self.currentViewController = nil
        super.init(nibName: nil, bundle: nil)
    }

    open override func loadView() {
        let containerView = UIView()
        #if !os(visionOS)
        containerView.backgroundColor = .systemBackground
        #endif

        if #available(iOS 17, visionOS 1, *) {
        } else {
            containerView.addSubview(emptyViewContainer)
            containerView.addSubview(loadingView)

            emptyViewContainer.translatesAutoresizingMaskIntoConstraints = false
            loadingView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                loadingView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                loadingView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                emptyViewContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                emptyViewContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
                emptyViewContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                emptyViewContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ])
            emptyViewContainer.isHidden = true
        }

        view = containerView
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            await reload()

            NotificationCenter.default.addObserver(self, selector: #selector(handleSubscriptionStatusChanged), name: .subscriptionStatusChanged, object: nil)
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func requestOpenSubscriptionManagement() {
        openSubscriptionManagement()
    }

    @objc private func handleSubscriptionStatusChanged() {
        switch subscriptionManager.status {
        case .verified:
            // We only handle not subscribed -> subscribed here
            break
        default:
            return
        }

        Task {
            await reload()
        }
    }

    private func reload() async {
        currentViewController?.remove()
        currentViewController = nil

        if #available(iOS 17, visionOS 1, *) {
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
        } else {
            loadingView.isHidden = false
            emptyViewContainer.isHidden = true
            loadingView.startAnimating()
        }

        let transactionInfo = subscriptionManager.transactionInfo()
        if transactionInfo == nil {
            if #available(iOS 17, visionOS 1, *) {
                var config = UIContentUnavailableConfiguration.empty()
                config.text = CelestiaString("This feature is only available to Celestia PLUS users.", comment: "")
                #if !targetEnvironment(macCatalyst)
                var button = UIButton.Configuration.filled()
                button.baseBackgroundColor = .buttonBackground
                button.baseForegroundColor = .buttonForeground
                config.button = button
                #endif
                config.button.title = CelestiaString("Get Celestia PLUS", comment: "")
                config.buttonProperties.primaryAction = UIAction { [weak self] _ in
                    guard let self else { return }
                    self.requestOpenSubscriptionManagement()
                }
                contentUnavailableConfiguration = config
            } else {
                loadingView.stopAnimating()
                loadingView.isHidden = true
                emptyViewContainer.isHidden = false
            }
        } else {
            let viewController = await viewControllerBuilder(self)
            if #available(iOS 17, visionOS 1, *) {
                contentUnavailableConfiguration = nil
            } else {
                loadingView.stopAnimating()
                loadingView.isHidden = true
            }
            install(viewController)
            observeWindowTitle(for: viewController)
            view.sendSubviewToBack(viewController.view)
            currentViewController = viewController
        }
    }
}
