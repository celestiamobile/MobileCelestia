//
// BodyDescriptionCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

final class BodyDescriptionCell: UICollectionViewCell {
    private var titleLabel = UILabel()
    private var bodyLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        titleLabel.textColor = .darkLabel
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byCharWrapping

        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            bodyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        bodyLabel.textColor = .darkSecondaryLabel
        bodyLabel.font = UIFont.preferredFont(forTextStyle: .body)
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byCharWrapping
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        attributes.size = contentView.systemLayoutSizeFitting(
            CGSize(width: layoutAttributes.size.width, height: 0),
            withHorizontalFittingPriority: UILayoutPriority.required,
            verticalFittingPriority: UILayoutPriority.defaultLow)
        return attributes
    }
}

extension BodyDescriptionCell {
    func update(with info: BodyInfo) {
        titleLabel.text = info.name
        bodyLabel.text = info.overview
    }
}
