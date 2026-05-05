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
        case inProgress(status: SubscriptionManager.SubscriptionStatus, plans: [SubscriptionManager.Plan], lifetimePlan: SubscriptionManager.LifetimePlan?, pendingProduct: Product)
        case status(status: SubscriptionManager.SubscriptionStatus, plans: [SubscriptionManager.Plan], lifetimePlan: SubscriptionManager.LifetimePlan?)
    }

    private var status = Status.empty

    private lazy var descriptiveLabel = UILabel(textStyle: .body, weight: .medium)
    private lazy var carouselPageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.isUserInteractionEnabled = false
        pageControl.numberOfPages = carouselItems.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .tertiaryLabel
        pageControl.currentPageIndicatorTintColor = .tintColor
        return pageControl
    }()

    private lazy var pageViewController: UIPageViewController = {
        let vc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        vc.dataSource = self
        vc.delegate = self
        return vc
    }()

    private lazy var featureView: UIView = {
        let view = UIView()
        descriptiveLabel.numberOfLines = 0
        descriptiveLabel.textAlignment = .center
        addChild(pageViewController)
        let pageVCView = pageViewController.view!
        pageVCView.backgroundColor = .clear
        if let firstItem = carouselItems.first {
            pageViewController.setViewControllers(
                [CarouselItemViewController(index: 0, item: firstItem)],
                direction: .forward,
                animated: false
            )
        }
        pageViewController.didMove(toParent: self)

        view.addSubview(pageVCView)
        view.addSubview(descriptiveLabel)
        view.addSubview(carouselPageControl)
        pageVCView.translatesAutoresizingMaskIntoConstraints = false
        descriptiveLabel.translatesAutoresizingMaskIntoConstraints = false
        carouselPageControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pageVCView.topAnchor.constraint(equalTo: view.topAnchor),
            pageVCView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageVCView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageVCView.heightAnchor.constraint(equalTo: pageVCView.widthAnchor, multiplier: 9.0/16.0),
            descriptiveLabel.topAnchor.constraint(equalTo: pageVCView.bottomAnchor, constant: GlobalConstants.pageMediumGapVertical),
            descriptiveLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            descriptiveLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carouselPageControl.topAnchor.constraint(equalTo: descriptiveLabel.bottomAnchor, constant: GlobalConstants.pageSmallGapVertical),
            carouselPageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            carouselPageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        updateDescriptiveLabel(for: 0)
        return view
    }()

    private lazy var carouselItems: [CarouselItemViewController.ItemType] = {
        var items: [CarouselItemViewController.ItemType] = []
        #if !targetEnvironment(macCatalyst)
        items.append(.video("Toolbar-iOS", CelestiaString("Toolbar Customization", comment: "Description for toolbar customization video")))
        #endif
        items.append(.video("Font", CelestiaString("Custom Fonts", comment: "Description for custom font video")))
        items.append(.video("Search", CelestiaString("Search Add-ons", comment: "Description for search add-ons video")))
        items.append(.video("Addon-Updates", CelestiaString("Add-on Updates", comment: "Description for addon updates video")))
        #if !targetEnvironment(macCatalyst)
        items.append(.video("App-Icon", CelestiaString("Custom App Icon", comment: "Description for custom app icon video")))
        #endif
        items.append(.support(
            CelestiaString("Support the Project", comment: "Description for support project card"),
            CelestiaString("By subscribing to Celestia PLUS, you directly support the developers and keep this project alive. You'll also receive timely feedback on feature requests and bug reports!", comment: "Message on support project card"),
            assetProvider
        ))
        return items
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
    func updateDescriptiveLabel(for page: Int) {
        guard carouselItems.indices.contains(page) else { return }
        let item = carouselItems[page]
        switch item {
        case let .video(_, title):
            descriptiveLabel.text = title
        case let .support(title, _, _):
            descriptiveLabel.text = title
        }
    }

    func reloadData() {
        status = .empty
        reloadViews()

        Task {
            do {
                var plans = try await subscriptionManager.fetchSubscriptionProducts(stringProvider: stringProvider)
                let lifetimePlan = try? await subscriptionManager.fetchLifetimeProduct(stringProvider: stringProvider)
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
                self.status = .status(status: status, plans: plans, lifetimePlan: lifetimePlan)
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
        case .status(let subscriptionStatus, let plans, let lifetimePlan), .inProgress(let subscriptionStatus, let plans, let lifetimePlan, _):
            if #available(iOS 17, *) {
                contentUnavailableConfiguration = nil
            } else {
                loadingView.isHidden = true
                loadingView.stopAnimating()
                errorView.isHidden = true
            }
            scrollContainer.isHidden = false
            let pendingProduct: Product?
            if case let Status.inProgress(_, _, _, product) = status {
                pendingProduct = product
            } else {
                pendingProduct = nil
            }
            setUpPlanList(subscriptionStatus: subscriptionStatus, plans: plans, lifetimePlan: lifetimePlan, pendingProduct: pendingProduct)
        }
    }

    private func setUpPlanList(subscriptionStatus: SubscriptionManager.SubscriptionStatus, plans: [SubscriptionManager.Plan], lifetimePlan: SubscriptionManager.LifetimePlan?, pendingProduct: Product?) {
        for planView in planStack.arrangedSubviews {
            planStack.removeArrangedSubview(planView)
            planView.removeFromSuperview()
        }
        let currentPlanCycle: SubscriptionManager.Plan.Cycle?
        let isLifetimeOwner: Bool
        let hasActiveSubscription: Bool
        let allDisabled: Bool
        switch subscriptionStatus {
        case let .verified(_, _, cycle, _, _):
            currentPlanCycle = cycle
            isLifetimeOwner = false
            hasActiveSubscription = true
            statusLabel.text = CelestiaString("Congratulations, you are a Celestia PLUS user", comment: "")
            allDisabled = false
        case .lifetime:
            currentPlanCycle = nil
            isLifetimeOwner = true
            hasActiveSubscription = false
            statusLabel.text = CelestiaString("Congratulations, you are a Celestia PLUS user", comment: "")
            allDisabled = false
        case .pending:
            currentPlanCycle = nil
            isLifetimeOwner = false
            hasActiveSubscription = false
            statusLabel.text = CelestiaString("Your purchase is pending", comment: "")
            allDisabled = true
        default:
            currentPlanCycle = nil
            isLifetimeOwner = false
            hasActiveSubscription = false
            statusLabel.text = CelestiaString("Choose one of the plans below to get access to all the features.", comment: "")
            allDisabled = false
        }
        if !isLifetimeOwner {
        for plan in plans {
            let product = plan.product
            var isCurrent = false
            let action: PlanView.Action
            if let currentPlanCycle {
                if plan.cycle == currentPlanCycle {
                    action = .empty
                    isCurrent = true
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
            let planView = PlanView(plan: plan, action: action, state: state, isCurrent: isCurrent) { [weak self] in
                guard let self else { return }
                guard let scene = self.view.window?.windowScene else { return }
                Task {
                    do {
                        self.status = .empty
                         self.status = .inProgress(status: subscriptionStatus, plans: plans, lifetimePlan: lifetimePlan, pendingProduct: product)
                        self.reloadViews()
                        let newStatus = try await self.subscriptionManager.purchase(product, cycle: plan.cycle, scene: scene)
                        self.status = .status(status: newStatus, plans: plans, lifetimePlan: lifetimePlan)
                        if case .verified = newStatus {
                            self.reloadData()
                        } else {
                            self.reloadViews()
                        }
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

        if !hasActiveSubscription, let lifetimePlan {
            let product = lifetimePlan.product
            let action: PlanView.Action
            let state: PlanView.State
            if isLifetimeOwner {
                action = .empty
                state = .disabled
            } else if allDisabled {
                action = .get
                state = .disabled
            } else if let pendingProduct, pendingProduct.id == product.id {
                action = .get
                state = .pending
            } else if pendingProduct != nil {
                action = .get
                state = .disabled
            } else {
                action = .get
                state = .normal
            }
            let lifetimeView = PlanView(lifetimePlan: lifetimePlan, action: action, state: state, isCurrent: isLifetimeOwner) { [weak self] in
                guard let self else { return }
                guard let scene = self.view.window?.windowScene else { return }
                Task {
                    do {
                        self.status = .empty
                        self.status = .inProgress(status: subscriptionStatus, plans: plans, lifetimePlan: lifetimePlan, pendingProduct: product)
                        self.reloadViews()
                        let newStatus = try await self.subscriptionManager.purchaseLifetime(product, scene: scene)
                        self.status = .status(status: newStatus, plans: plans, lifetimePlan: lifetimePlan)
                        if case .lifetime = newStatus {
                            self.reloadData()
                        } else {
                            self.reloadViews()
                        }
                    } catch {
                        self.status = .error
                        self.reloadViews()
                    }
                }
            }
            lifetimeView.layer.cornerRadius = Constants.boxCornerRadius
            planStack.addArrangedSubview(lifetimeView)
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

extension SubscriptionManagerViewController: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? CarouselItemViewController else { return nil }
        let prevIndex = vc.index - 1
        guard prevIndex >= 0 else { return nil }
        return CarouselItemViewController(index: prevIndex, item: carouselItems[prevIndex])
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? CarouselItemViewController else { return nil }
        let nextIndex = vc.index + 1
        guard nextIndex < carouselItems.count else { return nil }
        return CarouselItemViewController(index: nextIndex, item: carouselItems[nextIndex])
    }
}

extension SubscriptionManagerViewController: UIPageViewControllerDelegate {
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let vc = pageViewController.viewControllers?.first as? CarouselItemViewController else { return }
        carouselPageControl.currentPage = vc.index
        updateDescriptiveLabel(for: vc.index)
    }
}

private class CarouselItemViewController: UIViewController {
    enum ItemType {
        case video(String, String)
        case support(String, String, AssetProvider)
    }

    let index: Int
    let item: ItemType

    private let videoView = CarouselVideoView()
    private let supportView = UIView()
    private let floatingIconsView = FloatingIconsView()
    private let messageLabel = UILabel(textStyle: .body, weight: .medium)

    init(index: Int, item: ItemType) {
        self.index = index
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        supportView.addSubview(floatingIconsView)
        supportView.addSubview(messageLabel)
        view.addSubview(videoView)
        view.addSubview(supportView)

        videoView.translatesAutoresizingMaskIntoConstraints = false
        supportView.translatesAutoresizingMaskIntoConstraints = false
        floatingIconsView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        supportView.backgroundColor = .secondarySystemFill
        supportView.layer.cornerRadius = 24
        supportView.clipsToBounds = true
        videoView.layer.cornerRadius = 24
        videoView.clipsToBounds = true

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = .label

        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            supportView.topAnchor.constraint(equalTo: view.topAnchor),
            supportView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            supportView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            supportView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            floatingIconsView.topAnchor.constraint(equalTo: supportView.topAnchor),
            floatingIconsView.leadingAnchor.constraint(equalTo: supportView.leadingAnchor),
            floatingIconsView.trailingAnchor.constraint(equalTo: supportView.trailingAnchor),
            floatingIconsView.bottomAnchor.constraint(equalTo: supportView.bottomAnchor),

            messageLabel.centerYAnchor.constraint(equalTo: supportView.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: supportView.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            messageLabel.trailingAnchor.constraint(equalTo: supportView.trailingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal),
        ])

        switch item {
        case .video(let videoName, _):
            videoView.isHidden = false
            supportView.isHidden = true
            videoView.load(videoName: videoName)
        case .support(_, let message, let assetProvider):
            videoView.isHidden = true
            supportView.isHidden = false
            messageLabel.text = message
            floatingIconsView.startAnimating(assetProvider: assetProvider)
        }
    }
}
