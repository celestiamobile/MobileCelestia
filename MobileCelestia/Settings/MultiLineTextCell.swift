//
// MultiLineTextCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class MultiLineTextCell: UITableViewCell {
    private lazy var label = UILabel(textStyle: .body)

    var title: String? { didSet { label.text = title }  }
    var attributedTitle: NSAttributedString? { didSet { label.attributedText = attributedTitle } }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension MultiLineTextCell {
    func setup() {
        if #available(iOS 13.0, *) {
        } else {
            backgroundColor = .darkSecondaryBackground
            selectedBackgroundView = UIView()
            selectedBackgroundView?.backgroundColor = .darkSelection
        }

        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.textColor = .darkLabel
        label.numberOfLines = 0

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMarginHorizontal),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -GlobalConstants.listItemMarginHorizontal),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GlobalConstants.listItemMarginVertical),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -GlobalConstants.listItemMarginVertical),
        ])

        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}
