// SubscriptionManagerViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import StoreKit
import UIKit

public class SubscriptionManagerViewController: UIViewController {
    private let subscriptionManager: SubscriptionManager
    private let assetProvider: AssetProvider
    private let stringProvider: StringProvider

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
            FeatureView(image: UIImage(systemName: "paintpalette"), description: CelestiaString("Customize the visual appearance of Celestia.", comment: "Benefits of Celestia PLUS")),
            FeatureView(image: UIImage(systemName: "clock.arrow.circlepath"), description: CelestiaString("Get latest add-ons, updates, and trending add-ons.", comment: "Benefits of Celestia PLUS")),
            FeatureView(image: UIImage(systemName: "checkmark.bubble"), description: CelestiaString("Receive timely feedback on feature requests and bug reports.", comment: "Benefits of Celestia PLUS")),
            FeatureView(image: UIImage(systemName: "heart"), description: CelestiaString("Support the developer community and keep the project going.", comment: "Benefits of Celestia PLUS")),
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
    private lazy var innerErrorView: EmptyHintView = {
        let view = EmptyHintView()
        view.title = CelestiaString("We encountered an error.", comment: "Error loading the subscription page")
        view.actionText = CelestiaString("Refresh", comment: "Button to refresh this list")
        view.action = { [weak self] in
            guard let self else { return }
            self.reloadData()
        }
        return view
    }()
    private lazy var errorView = SafeAreaView(view: innerErrorView)
    private lazy var scrollContainer = UIScrollView()
    private lazy var planStack = UIStackView(arrangedSubviews: [])
    private lazy var containerView = UIView()

    public init(subscriptionManager: SubscriptionManager, assetProvider: AssetProvider, stringProvider: StringProvider) {
        self.subscriptionManager = subscriptionManager
        self.assetProvider = assetProvider
        self.stringProvider = stringProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        #if !os(visionOS)
        containerView.backgroundColor = .systemBackground
        #endif

        NSLayoutConstraint.activate([
            scrollContainer.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollContainer.widthAnchor)
        ])

        let scaling = GlobalConstants.preferredUIElementScaling(for: containerView.traitCollection)
        let appIconView = IconView(image: assetProvider.image(for: .loadingIcon), baseSize: CGSize(width: Constants.appIconDimension * scaling, height: Constants.appIconDimension * scaling)) { imageView in
            imageView.contentMode = .scaleAspectFit
        }

        let titleLabel = UILabel(textStyle: .title1, weight: .semibold)
        titleLabel.numberOfLines = 0
        titleLabel.text = CelestiaString("Celestia PLUS", comment: "Name for the subscription service")
        statusLabel.numberOfLines = 0

        planStack.axis = .vertical
        planStack.spacing = GlobalConstants.pageMediumGapVertical

        featureView.layer.cornerRadius = Constants.boxCornerRadius

        let button = ActionButtonHelper.newButton(prominent: true, traitCollection: traitCollection)
        button.setTitle(CelestiaString("Restore Purchase", comment: "Refresh purchase status"), for: .normal)
        button.addTarget(self, action: #selector(restorePurchases), for: .touchUpInside)

        let eulaText = CelestiaString("End User License Agreements (EULA)", comment: "")
        let privacyText = CelestiaString("Privacy Policy and Service Agreement", comment: "Privacy Policy and Service Agreement")

        let linkView = LinkTextConfiguration(info: LinkTextConfiguration.LinkInfo(text: ListFormatter.localizedString(byJoining: [eulaText, privacyText]), links: [
            LinkTextConfiguration.Link(text: eulaText, link: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
            LinkTextConfiguration.Link(text: privacyText, link: "https://celestia.mobi/privacy"),
        ])).makeContentView()

        let contents = [(appIconView, false), (titleLabel, false), (featureView, true), (statusLabel, true), (planStack, true), (linkView, true), (button, true)]
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

        containerView.addSubview(scrollContainer)
        containerView.addSubview(errorView)
        containerView.addSubview(loadingView)
        scrollContainer.isHidden = true
        errorView.isHidden = true
        loadingView.isHidden = true

        scrollContainer.translatesAutoresizingMaskIntoConstraints = false
        errorView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            errorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            errorView.topAnchor.constraint(equalTo: containerView.topAnchor),
            errorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            loadingView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])

        view = containerView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        windowTitle = CelestiaString("Celestia PLUS", comment: "Name for the subscription service")
        reloadData()
    }
}

private extension SubscriptionManagerViewController {
    func reloadData() {
        status = .empty
        reloadViews()

        Task {
            do {
                var plans = try await subscriptionManager.fetchSubscriptionProducts(stringProvider: stringProvider)
                let status = await self.subscriptionManager.checkSubscriptionStatus()
                if let lastPlan = plans.last, lastPlan.cycle == .weekly {
                    plans.removeLast()
                    var isOnWeeklyPlan = false
                    if case let .verified(_, _, cycle, _, _) = status, cycle == .weekly {
                        isOnWeeklyPlan = true
                    }
                    if isOnWeeklyPlan || lastPlan.offersFreeTrial {
                        plans.insert(lastPlan, at: 0)
                    }
                }
                self.status = .status(status: status, plans: plans)
                reloadViews()
            } catch {
                status = .error
                reloadViews()
            }
        }
    }

    func reloadViews() {
        switch status {
        case .empty:
            if #available(iOS 17, *) {
                contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
            } else {
                loadingView.isHidden = false
                loadingView.startAnimating()
                errorView.isHidden = true
            }
            scrollContainer.isHidden = true
        case .error:
            if #available(iOS 17, *) {
                var config = UIContentUnavailableConfiguration.empty()
                config.text = CelestiaString("We encountered an error.", comment: "Error loading the subscription page")
                #if os(visionOS)
                config.button = .filled()
                #else
                if #available(iOS 26, *) {
                    config.button = .prominentGlass()
                } else {
                    config.button = .filled()
                }
                #endif
                config.button.title = CelestiaString("Refresh", comment: "Button to refresh this list")
                config.buttonProperties.primaryAction = UIAction { [weak self] _ in
                    guard let self else { return }
                    self.reloadData()
                }
                contentUnavailableConfiguration = config
            } else {
                loadingView.isHidden = true
                loadingView.stopAnimating()
                errorView.isHidden = false
            }
            scrollContainer.isHidden = true
        case .status(let subscriptionStatus, let plans), .inProgress(let subscriptionStatus, let plans, _):
            if #available(iOS 17, *) {
                contentUnavailableConfiguration = nil
            } else {
                loadingView.isHidden = true
                loadingView.stopAnimating()
                errorView.isHidden = true
            }
            scrollContainer.isHidden = false
            let pendingProduct: Product?
            if case let Status.inProgress(_, _, product) = status {
                pendingProduct = product
            } else {
                pendingProduct = nil
            }
            setUpPlanList(subscriptionStatus: subscriptionStatus, plans: plans, pendingProduct: pendingProduct)
        }
    }

    private func setUpPlanList(subscriptionStatus: SubscriptionManager.SubscriptionStatus, plans: [SubscriptionManager.Plan], pendingProduct: Product?) {
        for planView in planStack.arrangedSubviews {
            planStack.removeArrangedSubview(planView)
            planView.removeFromSuperview()
        }
        let currentPlanCycle: SubscriptionManager.Plan.Cycle?
        let allDisabled: Bool
        switch subscriptionStatus {
        case let .verified(_, _, cycle, _, _):
            currentPlanCycle = cycle
            statusLabel.text = CelestiaString("Congratulations, you are a Celestia PLUS user", comment: "")
            allDisabled = false
        case .pending:
            currentPlanCycle = nil
            statusLabel.text = CelestiaString("Your purchase is pending", comment: "")
            allDisabled = true
        default:
            currentPlanCycle = nil
            statusLabel.text = CelestiaString("Choose one of the plans below to get Celestia PLUS", comment: "")
            allDisabled = false
        }
        for plan in plans {
            let product = plan.product
            let action: PlanView.Action
            if let currentPlanCycle {
                if plan.cycle == currentPlanCycle {
                    action = .empty
                } else if currentPlanCycle.rawValue < plan.cycle.rawValue {
                    action = .upgrade
                } else {
                    if plan.cycle == .weekly {
                        // Block downgrading to weekly
                        continue
                    }
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
                guard let scene = self.view.window?.windowScene else { return }
                Task {
                    do {
                        self.status = .empty
                         self.status = .inProgress(status: subscriptionStatus, plans: plans, pendingProduct: product)
                        self.reloadViews()
                        let newStatus = try await self.subscriptionManager.purchase(product, cycle: plan.cycle, scene: scene)
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
