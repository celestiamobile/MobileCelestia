// BodyDescriptionCell.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

final class BodyDescriptionCell: UICollectionViewCell {
    private lazy var descriptionLabel = UITextView()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [descriptionLabel])
        stackView.axis = .vertical
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

        descriptionLabel.backgroundColor = .clear
        descriptionLabel.textContainer.maximumNumberOfLines = 0
        descriptionLabel.textContainerInset = UIEdgeInsets(top: 0, left: -descriptionLabel.textContainer.lineFragmentPadding, bottom: 0, right: -descriptionLabel.textContainer.lineFragmentPadding)
        descriptionLabel.isScrollEnabled = false
        descriptionLabel.isEditable = false
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.textContainer.lineBreakMode = .byWordWrapping
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

extension BodyDescriptionCell {
    func update(with info: BodyInfo, showTitle: Bool) {
        let attributedString = NSMutableAttributedString()
        if showTitle {
            attributedString.append(NSAttributedString(string: info.name, attributes: [.foregroundColor: UIColor.label, .font: UIFont.preferredFont(forTextStyle: .title2, weight: .semibold)]))

            let gap = NSMutableParagraphStyle()
            gap.lineSpacing = GlobalConstants.pageMediumGapVertical
            attributedString.append(NSAttributedString(string: "\n", attributes: [.paragraphStyle: gap]))
        }
        attributedString.append(NSAttributedString(string: info.overview, attributes: [.foregroundColor: UIColor.secondaryLabel, .font: UIFont.preferredFont(forTextStyle: .body)]))
        descriptionLabel.attributedText = attributedString
    }
}
