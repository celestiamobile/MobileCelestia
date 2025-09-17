// PlanView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import StoreKit
import UIKit

@available(iOS 15, *)
final class PlanView: UIView {
    enum Action {
        case upgrade
        case downgrade
        case get
        case empty
    }

    enum State {
        case pending
        case normal
        case disabled
    }

    private let product: Product
    private let handler: () -> Void

    init(plan: SubscriptionManager.Plan, action: Action, state: State, handler: @escaping () -> Void) {
        self.product = plan.product
        self.handler = handler

        super.init(frame: .zero)

        backgroundColor = .systemFill

        let nameLabel = UILabel(textStyle: .body)
        nameLabel.numberOfLines = 0
        nameLabel.textColor = .label
        let priceLabel = UILabel(textStyle: .body)
        priceLabel.textColor = .secondaryLabel
        priceLabel.numberOfLines = 0

        nameLabel.text = plan.name
        priceLabel.text = product.displayPrice

        let stack = UIStackView(arrangedSubviews: [nameLabel, priceLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = GlobalConstants.pageSmallGapVertical
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: GlobalConstants.pageSmallMarginHorizontal),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: GlobalConstants.pageSmallMarginVertical),
        ])

        let trailingView: UIView
        switch state {
        case .pending:
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.startAnimating()
            trailingView = indicator
        case .normal:
            fallthrough
        case .disabled:
            let text: String
            let hidden: Bool
            let prominent: Bool
            switch action {
            case .upgrade:
                text = CelestiaString("Upgrade", comment: "Upgrade subscription service")
                hidden = false
                prominent = true
            case .downgrade:
                text = CelestiaString("Downgrade", comment: "Downgrade subscription service")
                hidden = false
                prominent = false
            case .get:
                text = CelestiaString("Get", comment: "Purchase subscription service")
                hidden = false
                prominent = true
            case .empty:
                text = ""
                hidden = true
                prominent = false
            }
            let actionButton = ActionButtonHelper.newButton(prominent: prominent, traitCollection: traitCollection)
            actionButton.setTitle(text, for: .normal)
            actionButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
            actionButton.isHidden = hidden
            actionButton.isEnabled = state != .disabled
            trailingView = actionButton
        }
        trailingView.setContentHuggingPriority(.required, for: .horizontal)
        trailingView.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(trailingView)
        trailingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trailingView.leadingAnchor.constraint(greaterThanOrEqualTo: stack.trailingAnchor, constant: GlobalConstants.pageSmallGapHorizontal),
            trailingView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -GlobalConstants.pageSmallMarginHorizontal),
            trailingView.centerYAnchor.constraint(equalTo: centerYAnchor),
            trailingView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: GlobalConstants.pageSmallMarginVertical)
        ])

        let optionalConstraints = [
            stack.topAnchor.constraint(equalTo: topAnchor, constant: GlobalConstants.pageSmallMarginVertical),
            trailingView.topAnchor.constraint(equalTo: topAnchor, constant: GlobalConstants.pageSmallMarginVertical)
        ]
        for constraint in optionalConstraints {
            constraint.priority = .defaultLow
        }
        NSLayoutConstraint.activate(optionalConstraints)
    }

    @objc private func handleTap() {
        handler()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
