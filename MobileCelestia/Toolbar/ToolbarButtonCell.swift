//
// ToolbarButtonCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import UIKit

@MainActor
protocol ToolbarCell: AnyObject {
    var itemTitle: String? { get set }
    var itemImage: UIImage? { get set }
    var itemAccessibilityLabel: String? { get set }
    var touchDownHandler: ((UIControl) -> Void)? { get set }
    var touchUpHandler: ((UIControl, Bool) -> Void)? { get set }
}

class ToolbarImageButtonCell: UICollectionViewCell, ToolbarCell {
    var itemTitle: String?
    var itemImage: UIImage? { didSet { button.setImage(itemImage, for: .normal) } }
    var itemAccessibilityLabel: String? { didSet { button.accessibilityLabel = itemAccessibilityLabel } }
    var touchDownHandler: ((UIControl) -> Void)?
    var touchUpHandler: ((UIControl, Bool) -> Void)?

    private lazy var button = StandardButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.tintColor = .label
        let padding = GlobalConstants.preferredUIElementScaling(for: traitCollection) * GlobalConstants.bottomControlViewItemPadding
        button.imageEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            button.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            button.heightAnchor.constraint(equalTo: contentView.heightAnchor),
        ])
        button.addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(touchUpOutside(_:)), for: .touchUpOutside)
        button.addTarget(self, action: #selector(touchCancelled(_:)), for: .touchCancel)
    }

    @objc private func touchDown(_ sender: UIButton) {
        touchDownHandler?(sender)
    }

    @objc private func touchUpInside(_ sender: UIButton) {
        touchUpHandler?(sender, true)
    }

    @objc private func touchUpOutside(_ sender: UIButton) {
        touchUpHandler?(sender, false)
    }

    @objc private func touchCancelled(_ sender: UIButton) {
        touchUpHandler?(sender, false)
    }
}

class ToolbarImageTextButtonCell: UITableViewCell, ToolbarCell {
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

    var itemTitle: String? { didSet { label.text = itemTitle } }
    var itemImage: UIImage? { didSet { iconImageView.configuration.image = itemImage?.withRenderingMode(.alwaysTemplate) } }
    var touchDownHandler: ((UIControl) -> Void)?
    var touchUpHandler: ((UIControl, Bool) -> Void)?
    var itemAccessibilityLabel: String?

    private lazy var iconImageView: IconView = {
        let dimension = GlobalConstants.preferredUIElementScaling(for: traitCollection) * Constants.iconDimension
        return IconView(baseSize: CGSize(width: dimension, height: dimension)) { imageView in
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .label
        }
    }()
    private lazy var label = UILabel(textStyle: .body)
    private lazy var background = SelectionView(frame: .zero)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        if #available(iOS 15, *) {
            background.focusEffect = UIFocusEffect()
        }
        background.translatesAutoresizingMaskIntoConstraints = false
        background.addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        background.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        background.addTarget(self, action: #selector(touchUpOutside(_:)), for: .touchUpOutside)
        background.addTarget(self, action: #selector(touchCancelled(_:)), for: .touchCancel)

        contentView.addSubview(background)
        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: contentView.topAnchor),
            background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            background.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
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
    }

    @objc private func touchDown(_ sender: UIButton) {
        touchDownHandler?(sender)
    }

    @objc private func touchUpInside(_ sender: UIButton) {
        touchUpHandler?(sender, true)
    }


    @objc private func touchUpOutside(_ sender: UIButton) {
        touchUpHandler?(sender, false)
    }

    @objc private func touchCancelled(_ sender: UIButton) {
        touchUpHandler?(sender, false)
    }
}

class ToolbarSeparatorCell: UITableViewHeaderFooterView {
    private enum Constants {
        static let separatorInsetLeading: CGFloat = 32
    }

    let sep = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.heightAnchor.constraint(equalToConstant: 1 / sep.traitCollection.displayScale),
            sep.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.separatorInsetLeading),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
}
