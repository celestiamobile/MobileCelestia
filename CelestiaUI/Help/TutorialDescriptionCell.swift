// TutorialDescriptionCell.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

class TutorialDescriptionCell: SelectableListCell {
    private enum Constants {
        static let iconDimension: CGFloat = 44
        static let gapHorizontal: CGFloat = 16
    }

    private lazy var label = UILabel(textStyle: .body)
    private lazy var iv = IconView(baseSize: CGSize(width: Constants.iconDimension, height: Constants.iconDimension)) { imageView in
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
    }

    var img: UIImage? { didSet { iv.configuration.image = img?.withRenderingMode(.alwaysTemplate) } }
    var title: String? { didSet { label.text = title }  }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TutorialDescriptionCell {
    func setup() {
        selectable = false
        backgroundStyle = .clear

        iv.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            iv.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
            iv.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -GlobalConstants.listItemMediumMarginVertical),
        ])

        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.textColor = .label
        label.numberOfLines = 0

        NSLayoutConstraint.activate([
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -GlobalConstants.listItemMediumMarginHorizontal),
            label.leadingAnchor.constraint(equalTo: iv.trailingAnchor, constant: Constants.gapHorizontal),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
            {
                let cons =
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -GlobalConstants.listItemMediumMarginVertical)
                cons.priority = .defaultHigh
                return cons
            }()
        ])

        let textBottomConstraint = label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -GlobalConstants.listItemMediumMarginVertical)
        textBottomConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([textBottomConstraint])
    }
}
