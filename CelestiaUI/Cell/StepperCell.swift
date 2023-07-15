//
// StepperCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

#if targetEnvironment(macCatalyst)
// Recreate the iOS 13 stepper
class FallbackStepper: UIControl {
    private enum Constants {
        static let separatorWidth: CGFloat = 1
        static let separatorMarginVertical: CGFloat = 7
        static let interactionVerticalTolerance: CGFloat = 44
        static let backgroundCornerRadius: CGFloat = 8
        static let stepperSingleWidth: CGFloat = 46.5
        static let stepperHeight: CGFloat = 32
    }

    enum StepperState {
        case plus
        case minus
        case empty
    }

    private(set) var stepperState: StepperState = .empty

    private lazy var leadingBackgroundView = UIView()
    private lazy var trailingBackgroundView = UIView()
    private lazy var leadingSelectedView = UIView()
    private lazy var trailingSelectedView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setUp()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
            updateViewCorners()
        }
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        if leadingBackgroundView.frame.contains(location) {
            if stepperState != .minus {
                stepperState = .minus
                valueChanged()
            }
            return true
        } else if trailingBackgroundView.frame.contains(location) {
            if stepperState != .plus {
                stepperState = .plus
                valueChanged()
            }
            return true
        }
        return false
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if stepperState != .empty {
            stepperState = .empty
            valueChanged()
        }
    }

    override func cancelTracking(with event: UIEvent?) {
        if stepperState != .empty {
            stepperState = .empty
            valueChanged()
        }
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        if leadingBackgroundView.frame.insetBy(dx: 0, dy: -Constants.interactionVerticalTolerance).contains(location) {
            if stepperState != .minus {
                stepperState = .minus
                valueChanged()
            }
        } else if trailingBackgroundView.frame.insetBy(dx: 0, dy: -Constants.interactionVerticalTolerance).contains(location) {
            if stepperState != .plus {
                stepperState = .plus
                valueChanged()
            }
        }
        return true
    }

    private func valueChanged() {
        switch stepperState {
        case .plus:
            leadingSelectedView.isHidden = true
            trailingSelectedView.isHidden = false
        case .minus:
            leadingSelectedView.isHidden = false
            trailingSelectedView.isHidden = true
        case .empty:
            leadingSelectedView.isHidden = true
            trailingSelectedView.isHidden = true
        }
        sendActions(for: .valueChanged)
    }

    private func setUpViewCorners() {
        for view in [leadingSelectedView, trailingSelectedView, leadingBackgroundView, trailingBackgroundView] {
            view.layer.cornerRadius = Constants.backgroundCornerRadius * GlobalConstants.preferredUIElementScaling(for: traitCollection)
            view.layer.cornerCurve = .continuous
        }
        updateViewCorners()
    }

    private func updateViewCorners() {
        if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
            leadingBackgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            trailingBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        } else {
            leadingBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            trailingBackgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
    }

    private func setUp() {
        leadingBackgroundView.backgroundColor = .tertiarySystemFill
        trailingBackgroundView.backgroundColor = .tertiarySystemFill
        leadingSelectedView.isHidden = true
        trailingSelectedView.isHidden = true
        leadingSelectedView.backgroundColor = .systemGray4
        trailingSelectedView.backgroundColor = .systemGray4
        setUpViewCorners()
        updateViewCorners()
        let separatorBackgroundView = UIView()
        separatorBackgroundView.backgroundColor = .tertiarySystemFill

        leadingBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        trailingBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        separatorBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        leadingSelectedView.translatesAutoresizingMaskIntoConstraints = false
        trailingSelectedView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(leadingBackgroundView)
        addSubview(separatorBackgroundView)
        addSubview(trailingBackgroundView)
        addSubview(leadingSelectedView)
        addSubview(trailingSelectedView)

        let separatorView = UIView()
        separatorView.backgroundColor = .systemFill
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorBackgroundView.addSubview(separatorView)

        NSLayoutConstraint.activate([
            leadingBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            leadingBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            leadingBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            trailingBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trailingBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            trailingBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            separatorBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorBackgroundView.leadingAnchor.constraint(equalTo: leadingBackgroundView.trailingAnchor),
            separatorBackgroundView.trailingAnchor.constraint(equalTo: trailingBackgroundView.leadingAnchor),

            separatorBackgroundView.widthAnchor.constraint(equalToConstant: Constants.separatorWidth),

            separatorView.topAnchor.constraint(equalTo: separatorBackgroundView.topAnchor, constant: Constants.separatorMarginVertical),
            separatorView.centerYAnchor.constraint(equalTo: separatorBackgroundView.centerYAnchor),
            separatorView.leadingAnchor.constraint(equalTo: separatorBackgroundView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: separatorBackgroundView.trailingAnchor),
        ])

        NSLayoutConstraint.activate([
            leadingSelectedView.leadingAnchor.constraint(equalTo: leadingBackgroundView.leadingAnchor),
            leadingSelectedView.topAnchor.constraint(equalTo: leadingBackgroundView.topAnchor),
            leadingSelectedView.bottomAnchor.constraint(equalTo: leadingBackgroundView.bottomAnchor),
            leadingSelectedView.trailingAnchor.constraint(equalTo: separatorBackgroundView.trailingAnchor),

            trailingSelectedView.trailingAnchor.constraint(equalTo: trailingBackgroundView.trailingAnchor),
            trailingSelectedView.topAnchor.constraint(equalTo: trailingBackgroundView.topAnchor),
            trailingSelectedView.bottomAnchor.constraint(equalTo: trailingBackgroundView.bottomAnchor),
            trailingSelectedView.leadingAnchor.constraint(equalTo: separatorBackgroundView.leadingAnchor),
        ])

        NSLayoutConstraint.activate([
            leadingBackgroundView.widthAnchor.constraint(equalTo: trailingBackgroundView.widthAnchor),
            leadingBackgroundView.widthAnchor.constraint(equalToConstant: Constants.stepperSingleWidth * GlobalConstants.preferredUIElementScaling(for: traitCollection)),
            leadingBackgroundView.heightAnchor.constraint(equalToConstant: Constants.stepperHeight * GlobalConstants.preferredUIElementScaling(for: traitCollection))
        ])

        for view in [leadingSelectedView, trailingSelectedView, leadingBackgroundView, trailingBackgroundView, separatorBackgroundView, separatorView] {
            view.isUserInteractionEnabled = false
        }

        let plusSignImageView = UIImageView(image: UIImage(systemName: "plus")?.withConfiguration(UIImage.SymbolConfiguration(weight: .medium)))
        let minusSignImageView = UIImageView(image: UIImage(systemName: "minus")?.withConfiguration(UIImage.SymbolConfiguration(weight: .medium)))
        plusSignImageView.tintColor = .label
        minusSignImageView.tintColor = .label

        minusSignImageView.translatesAutoresizingMaskIntoConstraints = false
        plusSignImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(minusSignImageView)
        addSubview(plusSignImageView)

        NSLayoutConstraint.activate([
            minusSignImageView.centerXAnchor.constraint(equalTo: leadingBackgroundView.centerXAnchor),
            minusSignImageView.centerYAnchor.constraint(equalTo: leadingBackgroundView.centerYAnchor),
            plusSignImageView.centerXAnchor.constraint(equalTo: trailingBackgroundView.centerXAnchor),
            plusSignImageView.centerYAnchor.constraint(equalTo: trailingBackgroundView.centerYAnchor),
        ])
    }
}
#endif

class StepperCell: UITableViewCell {
    private lazy var label = UILabel(textStyle: .body)
    #if targetEnvironment(macCatalyst)
    private lazy var stepper = FallbackStepper()
    #else
    private lazy var stepper = UIStepper()
    private var stepperValue: Double = 0
    #endif

    var title: String? { didSet { label.text = title }  }

    var changeBlock: ((Bool) -> Void)?
    var stopBlock: (() -> Void)?

    private enum Button {
        case plus
        case minus
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension StepperCell {
    func setup() {
        selectionStyle = .none

        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.textColor = .label
        label.numberOfLines = 0

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
        ])

        stepper.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stepper)
        NSLayoutConstraint.activate([
            stepper.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: GlobalConstants.listItemGapHorizontal),
            stepper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -GlobalConstants.listItemMediumMarginHorizontal),
            stepper.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stepper.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemAccessoryMinMarginVertical),
        ])

        #if !targetEnvironment(macCatalyst)
        stepper.wraps = true
        stepperValue = stepper.value
        stepper.addTarget(self, action: #selector(handleTouchUp(_:)), for: .touchUpInside)
        stepper.addTarget(self, action: #selector(handleTouchUp(_:)), for: .touchUpOutside)
        stepper.addTarget(self, action: #selector(handleTouchUp(_:)), for: .touchCancel)
        #endif
        stepper.addTarget(self, action: #selector(handleChange(_:)), for: .valueChanged)
    }

    #if targetEnvironment(macCatalyst)
    @objc private func handleChange(_ sender: FallbackStepper) {
        let state = sender.stepperState
        switch state {
        case .empty:
            stopBlock?()
        case .minus:
            changeBlock?(false)
        case .plus:
            changeBlock?(true)
        }
    }
    #else
    @objc private func handleChange(_ sender: UIStepper) {
        let orig = stepperValue
        let newValue = sender.value
        var isPlus = orig < newValue
        var isMinus = orig > newValue
        if sender.wraps {
            if orig > sender.maximumValue - sender.stepValue {
                isPlus = newValue < sender.minimumValue + sender.stepValue
                isMinus = isMinus && !isPlus
            } else if orig < sender.minimumValue + sender.stepValue {
                isMinus = newValue > sender.maximumValue - sender.stepValue
                isPlus = isPlus && !isMinus
            }
        }
        stepperValue = sender.value
        changeBlock?(isPlus)
    }
    #endif

    #if !targetEnvironment(macCatalyst)
    @objc private func handleTouchUp(_ sender: UIStepper) {
        stopBlock?()
    }
    #endif
}
