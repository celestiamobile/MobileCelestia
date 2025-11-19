// TextCell.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

public class TextCell: UITableViewCell {
    private lazy var label = UILabel(textStyle: .body)
    private lazy var subtitleLabel = UILabel(textStyle: .footnote)
    private lazy var detailLabel = UILabel(textStyle: .body)

    public var title: String? { didSet { label.text = title }  }
    public var titleColor: UIColor? { didSet { label.textColor = titleColor } }
    public var detail: String? { didSet { detailLabel.text = detail } }
    public var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = subtitle == nil
            if (subtitle == nil) != (oldValue == nil) {
                setNeedsLayout()
                layoutIfNeeded()
            }
        }
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
        let labelSize = label.sizeThatFits(maxLayoutSpace)
        let subtitleLabelSize = subtitleLabel.sizeThatFits(maxLayoutSpace)
        let trailingSize = detailLabel.sizeThatFits(maxLayoutSpace)
        let leadingSize: CGSize
        if subtitle != nil {
            leadingSize = CGSize(width: max(labelSize.width, subtitleLabelSize.width), height: labelSize.height + GlobalConstants.listTextGapVertical + subtitleLabelSize.height)
        } else {
            leadingSize = labelSize
        }
        if leadingSize.width < 0.01 || trailingSize.width < 0.01 || leadingSize.width + trailingSize.width < (maxLayoutSpace.width - GlobalConstants.listItemGapHorizontal)  {
            let horizontalCellHeight = max(leadingSize.height, trailingSize.height) + 2 * GlobalConstants.listItemMediumMarginVertical
            return CGSize(width: size.width, height: horizontalCellHeight)
        }
        return CGSize(width: size.width, height: leadingSize.height + trailingSize.height + 2 * GlobalConstants.listItemMediumMarginVertical + GlobalConstants.listItemGapVertical)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let maxLayoutSpace = CGSize(width: contentView.frame.width - 2 * GlobalConstants.listItemMediumMarginHorizontal, height: CGFloat.infinity)
        let isRTL = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft

        let labelSize = label.sizeThatFits(maxLayoutSpace)
        let subtitleLabelSize = subtitleLabel.sizeThatFits(maxLayoutSpace)
        let trailingSize = detailLabel.sizeThatFits(maxLayoutSpace)
        let leadingSize: CGSize
        if subtitle != nil {
            leadingSize = CGSize(width: max(labelSize.width, subtitleLabelSize.width), height: labelSize.height + GlobalConstants.listTextGapVertical + subtitleLabelSize.height)
        } else {
            leadingSize = labelSize
        }
        if leadingSize.width < 0.01 || trailingSize.width < 0.01 || leadingSize.width + trailingSize.width < (maxLayoutSpace.width - GlobalConstants.listItemGapHorizontal)  {
            let horizontalCellHeight = max(leadingSize.height, trailingSize.height) + 2 * GlobalConstants.listItemMediumMarginVertical
            if isRTL {
                detailLabel.frame = CGRect(x: GlobalConstants.listItemMediumMarginHorizontal, y: (horizontalCellHeight - trailingSize.height) / 2, width: trailingSize.width, height: trailingSize.height)

                var y = (horizontalCellHeight - leadingSize.height) / 2
                label.frame = CGRect(x: contentView.frame.width - GlobalConstants.listItemMediumMarginHorizontal - labelSize.width, y: y, width: labelSize.width, height: labelSize.height)

                if subtitle != nil {
                    y += (labelSize.height + GlobalConstants.listTextGapVertical)
                    subtitleLabel.frame = CGRect(x: contentView.frame.width - GlobalConstants.listItemMediumMarginHorizontal - subtitleLabelSize.width, y: y, width: subtitleLabelSize.width, height: subtitleLabelSize.height)
                }
            } else {
                detailLabel.frame = CGRect(x: contentView.frame.width - GlobalConstants.listItemMediumMarginHorizontal - trailingSize.width, y: (horizontalCellHeight - trailingSize.height) / 2, width: trailingSize.width, height: trailingSize.height)

                var y = (horizontalCellHeight - leadingSize.height) / 2
                label.frame = CGRect(x: GlobalConstants.listItemMediumMarginHorizontal, y: y, width: labelSize.width, height: labelSize.height)

                if subtitle != nil {
                    y += (labelSize.height + GlobalConstants.listTextGapVertical)
                    subtitleLabel.frame = CGRect(x: GlobalConstants.listItemMediumMarginHorizontal, y: y, width: subtitleLabelSize.width, height: subtitleLabelSize.height)
                }
            }
            return
        }

        var y: CGFloat = GlobalConstants.listItemMediumMarginVertical
        if isRTL {
            label.frame = CGRect(x: contentView.frame.width - GlobalConstants.listItemMediumMarginHorizontal - labelSize.width, y: y, width: labelSize.width, height: labelSize.height)
        } else {
            label.frame = CGRect(x: GlobalConstants.listItemMediumMarginHorizontal, y: y, width: labelSize.width, height: labelSize.height)
        }
        y += labelSize.height
        if subtitle != nil {
            y += GlobalConstants.listTextGapVertical
            if isRTL {
                subtitleLabel.frame = CGRect(x: contentView.frame.width - GlobalConstants.listItemMediumMarginHorizontal - subtitleLabelSize.width, y: y, width: subtitleLabelSize.width, height: subtitleLabelSize.height)
            } else {
                subtitleLabel.frame = CGRect(x: GlobalConstants.listItemMediumMarginHorizontal, y: y, width: subtitleLabelSize.width, height: subtitleLabelSize.height)
            }
            y += subtitleLabelSize.height
        }
        y += GlobalConstants.listItemGapVertical
        if isRTL {
            detailLabel.frame = CGRect(x: contentView.frame.width - GlobalConstants.listItemMediumMarginHorizontal - trailingSize.width, y: y, width: trailingSize.width, height: trailingSize.height)
        } else {
            detailLabel.frame = CGRect(x: GlobalConstants.listItemMediumMarginHorizontal, y: y, width: trailingSize.width, height: trailingSize.height)
        }
    }
}

private extension TextCell {
    func setUp() {
        contentView.addSubview(label)
        label.textColor = .label

        label.numberOfLines = 0

        contentView.addSubview(subtitleLabel)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.isHidden = true

        contentView.addSubview(detailLabel)
        detailLabel.textColor = .tertiaryLabel

        detailLabel.numberOfLines = 0
    }
}
