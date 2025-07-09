//
// SearchResultViewController.swift
//
// Copyright (C) 2025-present, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

final class BodySwitchCell: UICollectionViewCell {
    var title: String? { didSet { label.text = title } }
    var actionHandler: ((BodyActionCell) -> Void)?

    public var enabled: Bool = false { didSet { `switch`.isOn = enabled } }
    public var toggleBlock: ((Bool) -> Void)?

    private lazy var label = UILabel(textStyle: .body)
    private lazy var `switch` = UISwitch()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(label)
        contentView.addSubview(`switch`)

        label.textColor = .label
        label.numberOfLines = 0

        label.translatesAutoresizingMaskIntoConstraints = false
        `switch`.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
        ])

        NSLayoutConstraint.activate([
            `switch`.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: GlobalConstants.listItemGapHorizontal),
            `switch`.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            `switch`.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            `switch`.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemAccessoryMinMarginVertical),
        ])
        `switch`.addTarget(self, action: #selector(handleToggle(_:)), for: .valueChanged)
    }

    @objc private func handleToggle(_ sender: UISwitch) {
        toggleBlock?(sender.isOn)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let fittingSize = contentView.systemLayoutSizeFitting(
            CGSize(width: layoutAttributes.size.width, height: 0),
            withHorizontalFittingPriority: UILayoutPriority.required,
            verticalFittingPriority: UILayoutPriority.defaultLow)
        attributes.size = fittingSize
        return attributes
    }
}
