//
// TextCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public class TextCell: UITableViewCell {
    private lazy var label = UILabel(textStyle: .body)
    private lazy var detailLabel = UILabel(textStyle: .body)

    public var title: String? { didSet { label.text = title }  }
    public var titleColor: UIColor? { didSet { label.textColor = titleColor } }
    public var detail: String? { didSet { detailLabel.text = detail } }

    public override func prepareForReuse() {
        super.prepareForReuse()

        label.text = nil
        detailLabel.text = nil
        label.textColor = .label
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUp()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let maxLayoutSpace = CGSize(width: contentView.frame.width - 2 * GlobalConstants.listItemMediumMarginHorizontal, height: CGFloat.infinity)
        let size1 = label.sizeThatFits(maxLayoutSpace)
        let size2 = detailLabel.sizeThatFits(maxLayoutSpace)
        if size1.width < 0.01 || size2.width < 0.01 || size1.width + size2.width < (maxLayoutSpace.width - GlobalConstants.listItemGapHorizontal)  {
            let horizontalCellHeight = max(size1.height, size2.height) + 2 * GlobalConstants.listItemMediumMarginVertical
            return CGSize(width: size.width, height: horizontalCellHeight)
        }
        return CGSize(width: size.width, height: size1.height + size2.height + 2 * GlobalConstants.listItemMediumMarginVertical + GlobalConstants.listItemGapVertical)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let maxLayoutSpace = CGSize(width: contentView.frame.width - 2 * GlobalConstants.listItemMediumMarginHorizontal, height: CGFloat.infinity)
        let isRTL = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft

        let size1 = label.sizeThatFits(maxLayoutSpace)
        let size2 = detailLabel.sizeThatFits(maxLayoutSpace)
        if size1.width < 0.01 || size2.width < 0.01 || size1.width + size2.width < (maxLayoutSpace.width - GlobalConstants.listItemGapHorizontal)  {
            let horizontalCellHeight = max(size1.height, size2.height) + 2 * GlobalConstants.listItemMediumMarginVertical
            if isRTL {
                label.frame = CGRect(x: contentView.frame.width - GlobalConstants.listItemMediumMarginHorizontal - size1.width, y: (horizontalCellHeight - size1.height) / 2, width: size1.width, height: size1.height)
                detailLabel.frame = CGRect(x: GlobalConstants.listItemMediumMarginHorizontal, y: (horizontalCellHeight - size2.height) / 2, width: size2.width, height: size2.height)
            } else {
                label.frame = CGRect(x: GlobalConstants.listItemMediumMarginHorizontal, y: (horizontalCellHeight - size1.height) / 2, width: size1.width, height: size1.height)
                detailLabel.frame = CGRect(x: contentView.frame.width - GlobalConstants.listItemMediumMarginHorizontal - size2.width, y: (horizontalCellHeight - size2.height) / 2, width: size2.width, height: size2.height)
            }
            return
        }

        var y: CGFloat = GlobalConstants.listItemMediumMarginVertical
        if isRTL {
            label.frame = CGRect(x: contentView.frame.width - GlobalConstants.listItemMediumMarginHorizontal - size1.width, y: y, width: size1.width, height: size1.height)
        } else {
            label.frame = CGRect(x: GlobalConstants.listItemMediumMarginHorizontal, y: y, width: size1.width, height: size1.height)
        }
        y += size1.height
        y += GlobalConstants.listItemGapVertical
        if isRTL {
            detailLabel.frame = CGRect(x: contentView.frame.width - GlobalConstants.listItemMediumMarginHorizontal - size2.width, y: y, width: size2.width, height: size2.height)
        } else {
            detailLabel.frame = CGRect(x: GlobalConstants.listItemMediumMarginHorizontal, y: y, width: size2.width, height: size2.height)
        }
    }
}

private extension TextCell {
    func setUp() {
        contentView.addSubview(label)
        label.textColor = .label

        label.numberOfLines = 0

        contentView.addSubview(detailLabel)
        detailLabel.textColor = .tertiaryLabel

        detailLabel.numberOfLines = 0
    }
}
