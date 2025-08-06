// SafeAreaView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

class SafeAreaView: UIView {
    private let view: UIView

    var manualSafeAreaInsets: UIEdgeInsets? {
        didSet {
            guard oldValue != manualSafeAreaInsets else { return }
            setNeedsUpdateConstraints()
        }
    }

    private lazy var safeAreaGuideConstraints = [NSLayoutConstraint]()
    private lazy var manualSafeAreaConstraints = [NSLayoutConstraint]()

    init(view: UIView) {
        self.view = view
        super.init(frame: .zero)

        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        if let manualSafeAreaInsets {
            NSLayoutConstraint.deactivate(safeAreaGuideConstraints)
            manualSafeAreaConstraints[0].constant = manualSafeAreaInsets.left
            manualSafeAreaConstraints[1].constant = manualSafeAreaInsets.right
            manualSafeAreaConstraints[2].constant = manualSafeAreaInsets.top
            NSLayoutConstraint.activate(manualSafeAreaConstraints)
        } else {
            NSLayoutConstraint.deactivate(manualSafeAreaConstraints)
            NSLayoutConstraint.activate(safeAreaGuideConstraints)
        }

        super.updateConstraints()
    }

    private func setUp() {
        let containerView = UIView()
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        safeAreaGuideConstraints = [
            containerView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor),
            containerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
        ]
        NSLayoutConstraint.activate(safeAreaGuideConstraints)

        manualSafeAreaConstraints = [
            containerView.leftAnchor.constraint(equalTo: leftAnchor),
            containerView.rightAnchor.constraint(equalTo: rightAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor)
        ]

        let bottomConstraint = containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        if #available(iOS 15, visionOS 1, *) {
            let keyboardTopConstraint = containerView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor)
            keyboardTopConstraint.priority = .defaultHigh
            keyboardTopConstraint.isActive = true
            bottomConstraint.priority = .defaultLow
        } else {
            bottomConstraint.priority = .required
        }
        bottomConstraint.isActive = true

        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            view.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            view.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor)
        ])
        let optionalConstraints = [
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.topAnchor.constraint(equalTo: containerView.topAnchor)
        ]
        for optionalConstraint in optionalConstraints {
            optionalConstraint.priority = .defaultHigh
        }
        NSLayoutConstraint.activate(optionalConstraints)
    }
}
