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
    private lazy var titleLabel = UITextView()
    private lazy var bodyLabel = UITextView()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stackView.axis = .vertical
        stackView.spacing = GlobalConstants.pageMediumGapVertical
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        titleLabel.backgroundColor = .clear
        titleLabel.textContainer.maximumNumberOfLines = 0
        titleLabel.textContainerInset = UIEdgeInsets(top: 0, left: -titleLabel.textContainer.lineFragmentPadding, bottom: 0, right: -titleLabel.textContainer.lineFragmentPadding)
        titleLabel.isScrollEnabled = false
        titleLabel.isEditable = false
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2, weight: .semibold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textContainer.lineBreakMode = .byWordWrapping
        titleLabel.textColor = .darkLabel

        bodyLabel.backgroundColor = .clear
        bodyLabel.textContainer.maximumNumberOfLines = 0
        bodyLabel.textContainerInset = UIEdgeInsets(top: 0, left: -bodyLabel.textContainer.lineFragmentPadding, bottom: 0, right: -bodyLabel.textContainer.lineFragmentPadding)
        bodyLabel.isScrollEnabled = false
        bodyLabel.isEditable = false
        bodyLabel.font = UIFont.preferredFont(forTextStyle: .body)
        bodyLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.textContainer.lineBreakMode = .byWordWrapping
        bodyLabel.textColor = .darkSecondaryLabel
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let fittingSize = contentView.systemLayoutSizeFitting(
            CGSize(width: layoutAttributes.size.width, height: 0),
            withHorizontalFittingPriority: UILayoutPriority.required,
            verticalFittingPriority: UILayoutPriority.defaultLow)
        attributes.size = CGSize(width: fittingSize.width.rounded(.down), height: fittingSize.height)
        return attributes
    }
}

extension BodyDescriptionCell {
    func update(with info: BodyInfo, showTitle: Bool) {
        titleLabel.text = info.name
        bodyLabel.text = info.overview
        titleLabel.isHidden = !showTitle
    }
}
