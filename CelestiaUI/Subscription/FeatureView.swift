// FeatureView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

final class FeatureView: UIView {
    private enum Constants {
        static let iconSize: CGFloat = 24
        static let iconPadding: CGFloat = 3
    }

    init(image: UIImage?, description: String) {
        super.init(frame: .zero)
        let scale = GlobalConstants.preferredUIElementScaling(for: traitCollection)
        let imageView = IconView(image: image, baseSize: CGSize(width: Constants.iconSize * scale, height: Constants.iconSize * scale)) { imageView in
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .label
        }
        addSubview(imageView)
        let label = UILabel(textStyle: .body)
        label.numberOfLines = 0
        label.textColor = .label
        label.text = description
        addSubview(label)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.iconPadding),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.iconPadding),
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: GlobalConstants.pageMediumGapHorizontal + Constants.iconPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: GlobalConstants.pageMediumGapHorizontal),
            label.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Constants.iconPadding),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
        ])

        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let optionalConstraints = [
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.iconPadding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]
        for constraint in optionalConstraints {
            constraint.priority = .defaultLow
        }
        NSLayoutConstraint.activate(optionalConstraints)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
