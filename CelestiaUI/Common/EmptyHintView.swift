//
// EmptyHintView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class EmptyHintView: UIView {
    var title: String {
        get { textLabel.text ?? "" }
        set { textLabel.text = newValue }
    }

    var actionText: String? {
        get {
            if actionButton.superview == nil || actionButton.isHidden {
                return nil
            } else {
                return actionButton.title(for: .normal) ?? ""
            }
        }
        set {
            if let newValue {
                actionButton.isHidden = false
                actionButton.setTitle(newValue, for: .normal)
            } else {
                actionButton.isHidden = true
                actionButton.setTitle(nil, for: .normal)
            }
            setNeedsUpdateConstraints()
        }
    }

    var action: (() -> Void)? {
        didSet {
            actionButton.isEnabled = action != nil
        }
    }

    private lazy var textLabel = UILabel(textStyle: .body)
    private lazy var actionButton = ActionButtonHelper.newButton()

    private var actionButtonVisibleConstraints = [NSLayoutConstraint]()
    private var actionButtonHiddenConstraints = [NSLayoutConstraint]()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setUp()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        if actionButton.isHidden {
            NSLayoutConstraint.deactivate(actionButtonVisibleConstraints)
            NSLayoutConstraint.activate(actionButtonHiddenConstraints)
        } else {
            NSLayoutConstraint.deactivate(actionButtonHiddenConstraints)
            NSLayoutConstraint.activate(actionButtonVisibleConstraints)
        }

        super.updateConstraints()
    }

    private func setUp() {
        let containerView = UIView()

        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        containerView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        containerView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        containerView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            containerView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: GlobalConstants.pageMediumMarginHorizontal)
        ])

        let optionalContainerConstraints = [
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: GlobalConstants.pageMediumMarginHorizontal)
        ]
        for optionalConstraint in optionalContainerConstraints {
            optionalConstraint.priority = .defaultHigh
        }
        NSLayoutConstraint.activate(optionalContainerConstraints)

        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)

        actionButton.isHidden = true
        actionButton.isEnabled = false
        actionButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        actionButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        actionButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        actionButton.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        textLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        textLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        textLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        containerView.addSubview(textLabel)
        containerView.addSubview(actionButton)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            textLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            textLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            actionButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ])

        let optionalConstraints = [
            textLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        ]
        for optionalConstraint in optionalConstraints {
            optionalConstraint.priority = .defaultHigh
        }
        NSLayoutConstraint.activate(optionalConstraints)

        actionButtonVisibleConstraints = [
            actionButton.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: GlobalConstants.pageMediumGapVertical),
            actionButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            actionButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
        ]

        let optionalVisibleConstraints = [
            actionButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        ]
        for optionalConstraint in optionalVisibleConstraints {
            optionalConstraint.priority = .defaultHigh
        }
        actionButtonVisibleConstraints.append(contentsOf: optionalVisibleConstraints)

        actionButtonHiddenConstraints = [
            textLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ]

        setNeedsUpdateConstraints()
    }

    @objc private func handleAction() {
        action?()
    }
}

