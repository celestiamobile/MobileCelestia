//
// TutorialDescriptionCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class TutorialDescriptionCell: UITableViewCell {
    private lazy var label = UILabel(textStyle: .body)
    private lazy var iv = UIImageView()

    var img: UIImage? { didSet { iv.image = img?.withRenderingMode(.alwaysTemplate) } }
    var title: String? { didSet { label.text = title }  }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TutorialDescriptionCell {
    func setup() {
        selectionStyle = .none
        backgroundColor = .clear

        let verticalSpacing: CGFloat = 12
        let horizontalSpacing: CGFloat = 16

        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .darkLabel
        contentView.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.heightAnchor.constraint(equalToConstant: 44),
            iv.widthAnchor.constraint(equalTo: iv.heightAnchor),
            iv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalSpacing),
            iv.topAnchor.constraint(equalTo: contentView.topAnchor, constant: verticalSpacing),
            iv.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -verticalSpacing),
        ])

        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)

        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.textColor = .darkLabel
        label.numberOfLines = 0

        NSLayoutConstraint.activate([
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalSpacing),
            label.leadingAnchor.constraint(equalTo: iv.trailingAnchor, constant: horizontalSpacing),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: verticalSpacing),
            {
                let cons =
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -verticalSpacing)
                cons.priority = .defaultHigh
                return cons
            }()
        ])

        let textBottomConstraint = label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -verticalSpacing)
        textBottomConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([textBottomConstraint])
    }
}
