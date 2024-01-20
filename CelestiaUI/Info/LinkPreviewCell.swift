//
// LinkPreviewCell.swift
//
// Copyright © 2021 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import LinkPresentation
import UIKit

final class LinkPreviewCell: UICollectionViewCell {
    func setMetaData(_ linkMetaData: LPLinkMetadata) {
        contentView.subviews.compactMap { $0 as? LPLinkView }.forEach { view in
            view.removeFromSuperview()
        }
        let linkPreview = LPLinkView(metadata: linkMetaData)
        linkPreview.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(linkPreview)
        NSLayoutConstraint.activate([
            linkPreview.topAnchor.constraint(equalTo: contentView.topAnchor),
            linkPreview.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            linkPreview.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            linkPreview.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
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
