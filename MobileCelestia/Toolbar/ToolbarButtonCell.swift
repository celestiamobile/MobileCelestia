// ToolbarButtonCell.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import UIKit

@MainActor
struct ToolbarEntryConfiguration: UIContentConfiguration {
    var itemTitle: String?
    var itemImage: UIImage?
    var touchDownHandler: ((UIControl) -> Void)?
    var touchUpHandler: ((UIControl, Bool) -> Void)?

    func makeContentView() -> UIView & UIContentView {
        return ToolbarEntryView(configuration: self)
    }

    nonisolated func updated(for state: UIConfigurationState) -> ToolbarEntryConfiguration {
        return self
    }
}

class ToolbarEntryView: UIView, UIContentView {
    private enum Constants {
        static let iconDimension: CGFloat = 24
        static let highlightAnimationDuration: TimeInterval = 0.1
        static let unhighlightAnimationDuration: TimeInterval = 0.05
    }

    private class SelectionView: UIControl {
        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = .clear
            #if targetEnvironment(macCatalyst)
            layer.cornerRadius = GlobalConstants.actionMenuItemCornerRadius
            layer.cornerCurve = .continuous
            #endif
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            UIView.animate(withDuration: Constants.highlightAnimationDuration) {
                let color = UIColor.systemFill.resolvedColor(with: self.traitCollection)
                self.layer.backgroundColor = color.cgColor
            }
            return true
        }

        override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
            UIView.animate(withDuration: Constants.unhighlightAnimationDuration) {
                self.layer.backgroundColor = UIColor.clear.cgColor
            }
        }

        override func cancelTracking(with event: UIEvent?) {
            layer.backgroundColor = UIColor.clear.cgColor
        }
    }

    private lazy var iconImageView: IconView = {
        let dimension = GlobalConstants.preferredUIElementScaling(for: traitCollection) * Constants.iconDimension
        return IconView(baseSize: CGSize(width: dimension, height: dimension)) { imageView in
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .label
        }
    }()
    private lazy var label = UILabel(textStyle: .body)
    private lazy var background = SelectionView(frame: .zero)
    private var currentConfiguration: ToolbarEntryConfiguration!

    var configuration: UIContentConfiguration {
        get {
            currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? ToolbarEntryConfiguration else {
                return
            }

            apply(configuration: newConfiguration)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(configuration: ToolbarEntryConfiguration) {
        super.init(frame: .zero)

        setUp()
        apply(configuration: configuration)
    }

    private func setUp() {
        background.focusEffect = UIFocusEffect()

        background.translatesAutoresizingMaskIntoConstraints = false
        background.addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        background.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        background.addTarget(self, action: #selector(touchUpOutside(_:)), for: .touchUpOutside)
        background.addTarget(self, action: #selector(touchCancelled(_:)), for: .touchCancel)

        addSubview(background)
        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        background.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.centerYAnchor.constraint(equalTo: background.centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            iconImageView.topAnchor.constraint(greaterThanOrEqualTo: background.topAnchor, constant: GlobalConstants.listItemAccessoryMinMarginVertical),
        ])

        background.addSubview(label)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: background.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
            label.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -GlobalConstants.listItemMediumMarginHorizontal),
            label.topAnchor.constraint(greaterThanOrEqualTo: background.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
        ])
        label.textColor = .label

        let optionalConstraints = [
            iconImageView.topAnchor.constraint(equalTo: background.topAnchor, constant: GlobalConstants.listItemAccessoryMinMarginVertical),
            label.topAnchor.constraint(equalTo: background.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
        ]
        for optionalConstraint in optionalConstraints {
            optionalConstraint.priority = .defaultLow
        }
        NSLayoutConstraint.activate(optionalConstraints)
    }

    private func apply(configuration: ToolbarEntryConfiguration) {
        currentConfiguration = configuration
        label.text = configuration.itemTitle
        iconImageView.configuration.image = configuration.itemImage?.withRenderingMode(.alwaysTemplate)
    }

    @objc private func touchDown(_ sender: UIButton) {
        currentConfiguration.touchDownHandler?(sender)
    }

    @objc private func touchUpInside(_ sender: UIButton) {
        currentConfiguration.touchUpHandler?(sender, true)
    }

    @objc private func touchUpOutside(_ sender: UIButton) {
        currentConfiguration.touchUpHandler?(sender, false)
    }

    @objc private func touchCancelled(_ sender: UIButton) {
        currentConfiguration.touchUpHandler?(sender, false)
    }
}

@MainActor
struct SeparatorConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        return SeparatorView(configuration: self)
    }

    nonisolated func updated(for state: UIConfigurationState) -> SeparatorConfiguration {
        return self
    }
}

class SeparatorView: UIView, UIContentView {
    enum Constants {
        static let separatorInsetLeading: CGFloat = 32
        static let separatorContainerHeight: CGFloat = 6
    }

    private let separator = UIView()

    private var currentConfiguration: SeparatorConfiguration!

    var configuration: UIContentConfiguration {
        get {
            currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? SeparatorConfiguration else {
                return
            }

            apply(configuration: newConfiguration)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(configuration: SeparatorConfiguration) {
        super.init(frame: .zero)

        setUp()
        apply(configuration: configuration)
    }

    private func apply(configuration: SeparatorConfiguration) {
        currentConfiguration = configuration
    }

    private func setUp() {
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1 / separator.traitCollection.displayScale),
            separator.centerYAnchor.constraint(equalTo: centerYAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.separatorInsetLeading),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightAnchor.constraint(equalToConstant: Constants.separatorContainerHeight),
        ])
    }
}
