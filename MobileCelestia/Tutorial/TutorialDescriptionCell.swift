//
//  TutorialDescriptionCell.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/3/1.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class TutorialDescriptionCell: UITableViewCell {
    private lazy var label = UILabel()
    private lazy var iv = UIImageView()

    var img: UIImage? { didSet { iv.image = img } }
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

        iv.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iv.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 16),
            iv.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)

        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.textColor = .darkLabel
        label.numberOfLines = 0

        NSLayoutConstraint.activate([
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.leadingAnchor.constraint(equalTo: iv.trailingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        let textBottomConstraint = label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        textBottomConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([textBottomConstraint])
    }
}
