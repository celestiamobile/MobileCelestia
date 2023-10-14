//
// SubscriptionManagerViewController.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import StoreKit
import UIKit

@available(iOS 15, *)
public class SubscriptionManagerViewController: UIViewController {
    private let subscriptionManager: SubscriptionManager

    private enum Constants {
        static let boxCornerRadius: CGFloat = 12
        static let appIconDimension: CGFloat = 128
    }

    enum Status {
        case empty
        case error
        case inProgress(status: SubscriptionManager.SubscriptionStatus, plans: [SubscriptionManager.Plan], pendingProduct: Product)
        case status(status: SubscriptionManager.SubscriptionStatus, plans: [SubscriptionManager.Plan])
    }

    private var status = Status.empty

    private lazy var featureView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemFill
        let features = [
            FeatureView(image: UIImage(systemName: "paintpalette"), description: CelestiaString("Customize the visual appearance of Celestia.", comment: "")),
            FeatureView(image: UIImage(systemName: "clock.arrow.circlepath"), description: CelestiaString("Get latest add-ons, updates, and trending add-ons.", comment: "")),
            FeatureView(image: UIImage(systemName: "checkmark.bubble"), description: CelestiaString("Receive timely feedback on feature requests and bug reports.", comment: "")),
            FeatureView(image: UIImage(systemName: "heart"), description: CelestiaString("Support the developer community and keep the project going.", comment: "")),
        ]
        let stackView = UIStackView(arrangedSubviews: features)
        stackView.axis = .vertical
        stackView.spacing = GlobalConstants.pageMediumGapVertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: GlobalConstants.pageMediumMarginVertical),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -GlobalConstants.pageMediumMarginVertical),
        ])
        return view
    }()

    private lazy var statusLabel = UILabel(textStyle: .body)
    private lazy var loadingView = UIActivityIndicatorView(style: .large)
    private lazy var errorView: UIView = {
        let hintLabel = UILabel(textStyle: .body)
        hintLabel.text = CelestiaString("We encountered an error.", comment: "")
        let button = ActionButtonHelper.newButton()
        button.setTitle(CelestiaString("Refresh", comment: ""), for: .normal)
        let stackView = UIStackView(arrangedSubviews: [hintLabel, button])
        stackView.axis = .vertical
        stackView.spacing = GlobalConstants.pageSmallGapVertical
        stackView.alignment = .center
        button.addTarget(self, action: #selector(reloadData), for: .touchUpInside)
        return stackView
    }()
    private lazy var scrollContainer = UIScrollView()
    private lazy var planStack = UIStackView(arrangedSubviews: [])
    private lazy var containerView = UIView()

    public init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        containerView.backgroundColor = .systemBackground

        NSLayoutConstraint.activate([
            scrollContainer.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollContainer.widthAnchor)
        ])

        let scaling = GlobalConstants.preferredUIElementScaling(for: containerView.traitCollection)
        let appIconView = IconView(image: UIImage(named: "loading_icon"), baseSize: CGSize(width: Constants.appIconDimension * scaling, height: Constants.appIconDimension * scaling)) { imageView in
            imageView.contentMode = .scaleAspectFit
        }

        let titleLabel = UILabel(textStyle: .title1, weight: .semibold)
        titleLabel.numberOfLines = 0
        titleLabel.text = CelestiaString("Celestia PLUS", comment: "")
        statusLabel.numberOfLines = 0

        planStack.axis = .vertical
        planStack.spacing = GlobalConstants.pageMediumGapVertical

        featureView.layer.cornerRadius = Constants.boxCornerRadius

        let button = ActionButtonHelper.newButton()
        button.setTitle(CelestiaString("Restore Purchase", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(restorePurchases), for: .touchUpInside)

        let contents = [(appIconView, false), (titleLabel, false), (featureView, true), (statusLabel, true), (planStack, true), (button, true)]
        var previousView: UIView?
        for (content, stretch) in contents {
            let topAnchor: NSLayoutYAxisAnchor
            let topSpacing: CGFloat
            if let previousView {
                topAnchor = previousView.bottomAnchor
                topSpacing = GlobalConstants.pageLargeGapVertical
            } else {
                topAnchor = scrollContainer.contentLayoutGuide.topAnchor
                topSpacing = GlobalConstants.pageSmallMarginVertical
            }
            content.translatesAutoresizingMaskIntoConstraints = false
            scrollContainer.addSubview(content)
            if !stretch {
                NSLayoutConstraint.activate([
                    content.centerXAnchor.constraint(equalTo: scrollContainer.contentLayoutGuide.centerXAnchor),
                ])
            } else {
                NSLayoutConstraint.activate([
                    content.leadingAnchor.constraint(equalTo: scrollContainer.contentLayoutGuide.leadingAnchor, constant: GlobalConstants.pageSmallMarginHorizontal),
                    content.trailingAnchor.constraint(equalTo: scrollContainer.contentLayoutGuide.trailingAnchor, constant: -GlobalConstants.pageSmallMarginHorizontal),
                ])
            }
            NSLayoutConstraint.activate([
                content.topAnchor.constraint(equalTo: topAnchor, constant: topSpacing),
            ])
            previousView = content
        }
        if let previousView {
            NSLayoutConstraint.activate([
                previousView.bottomAnchor.constraint(equalTo: scrollContainer.contentLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageSmallMarginVertical)
            ])
        }

        view = containerView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        reloadData()
    }
}

@available(iOS 15.0, *)
private extension SubscriptionManagerViewController {
    @objc func reloadData() {
        status = .empty
        reloadViews()

        Task {
            do {
                let plans = try await subscriptionManager.fetchSubscriptionProducts().sorted(by: { $0.product.price > $1.product.price })
                let status = await self.subscriptionManager.checkSubscriptionStatus()
                self.status = .status(status: status, plans: plans)
                reloadViews()
            } catch {
                status = .error
                reloadViews()
            }
        }
    }

    func reloadViews() {
        let view: UIView
        let stretch: Bool
        switch status {
        case .empty:
            view = loadingView
            loadingView.startAnimating()
            stretch = false
        case .error:
            view = errorView
            loadingView.stopAnimating()
            stretch = false
        case .status(let subscriptionStatus, let plans), .inProgress(let subscriptionStatus, let plans, _):
            view = scrollContainer
            loadingView.stopAnimating()
            let pendingProduct: Product?
            if case let Status.inProgress(_, _, product) = status {
                pendingProduct = product
            } else {
                pendingProduct = nil
            }
            setUpPlanList(subscriptionStatus: subscriptionStatus, plans: plans, pendingProduct: pendingProduct)
            stretch = true
        }

        if containerView.subviews.contains(view) {
            return
        }

        for subview in containerView.subviews {
            subview.removeFromSuperview()
        }

        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])

        if stretch {
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                view.topAnchor.constraint(equalTo: containerView.topAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
                view.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor),
            ])
        }
    }

    private func setUpPlanList(subscriptionStatus: SubscriptionManager.SubscriptionStatus, plans: [SubscriptionManager.Plan], pendingProduct: Product?) {
        for planView in planStack.arrangedSubviews {
            planStack.removeArrangedSubview(planView)
            planView.removeFromSuperview()
        }
        let currentPlanIndex: Int?
        let allDisabled: Bool
        switch subscriptionStatus {
        case .verified(_, let productID, _, _):
            currentPlanIndex = plans.firstIndex(where: { $0.product.id == productID })
            statusLabel.text = CelestiaString("Congratulations, you are a Celestia PLUS user", comment: "")
            allDisabled = false
        case .pending:
            currentPlanIndex = nil
            statusLabel.text = CelestiaString("Your purchase is pending", comment: "")
            allDisabled = true
        default:
            currentPlanIndex = nil
            statusLabel.text = CelestiaString("Choose one of the plans below to get Celestia PLUS", comment: "")
            allDisabled = false
        }
        for (index, plan) in plans.enumerated() {
            let product = plan.product
            let action: PlanView.Action
            if let currentPlanIndex {
                if index == currentPlanIndex {
                    action = .empty
                } else if index < currentPlanIndex {
                    action = .upgrade
                } else {
                    action = .downgrade
                }
            } else {
                action = .get
            }
            let state: PlanView.State
            if allDisabled {
                state = .disabled
            } else if let pendingProduct {
                if product.id == pendingProduct.id {
                    state = .pending
                } else {
                    state = .disabled
                }
            } else {
                state = .normal
            }
            let planView = PlanView(plan: plan, action: action, state: state) { [weak self] in
                guard let self else { return }
                Task {
                    do {
                        self.status = .empty
                         self.status = .inProgress(status: subscriptionStatus, plans: plans, pendingProduct: product)
                        self.reloadViews()
                        let newStatus = try await self.subscriptionManager.purchase(product)
                        self.status = .status(status: newStatus, plans: plans)
                        self.reloadViews()
                    } catch {
                        self.status = .error
                        self.reloadViews()
                    }
                }
            }
            planView.layer.cornerRadius = Constants.boxCornerRadius
            planStack.addArrangedSubview(planView)
        }
    }

    @objc private func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()
                reloadData()
            } catch {}
        }
    }
}
