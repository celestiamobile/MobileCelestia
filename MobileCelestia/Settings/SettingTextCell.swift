//
// SettingTextCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class SettingTextCell: UITableViewCell {
    private lazy var label = UILabel()
    private lazy var detailLabel = UILabel()

    var title: String? { didSet { label.text = title }  }
    var titleColor: UIColor? { didSet { label.textColor = titleColor } }
    var detail: String? { didSet { detailLabel.text = detail } }

    private var savedAccessoryType: UITableViewCell.AccessoryType = .none

    override var accessoryType: UITableViewCell.AccessoryType {
        get {
            if #available(iOS 13, *) {
                return super.accessoryType
            }
            return savedAccessoryType
        }
        set {
            if #available(iOS 13, *) {
                super.accessoryType = newValue
                return
            }
            savedAccessoryType = newValue
            switch newValue {
            case .none:
                accessoryView = nil
            case .disclosureIndicator:
                let view = UIImageView(image: #imageLiteral(resourceName: "accessory_full_disclosure").withRenderingMode(.alwaysTemplate))
                view.tintColor = UIColor.darkTertiaryLabel
                accessoryView = view
            default:
                accessoryView = nil
                super.accessoryType = newValue
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        label.text = nil
        detailLabel.text = nil
        label.textColor = .darkLabel

        super.accessoryType = .none
        savedAccessoryType = .none
        accessoryView = nil
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SettingTextCell {
    func setup() {
        backgroundColor = .darkSecondaryBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .darkSelection

        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.textColor = .darkLabel

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
        ])

        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailLabel)
        detailLabel.textColor = .darkTertiaryLabel

        detailLabel.font = UIFont.preferredFont(forTextStyle: .body)
        detailLabel.numberOfLines = 0

        NSLayoutConstraint.activate([
            detailLabel.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 16),
            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detailLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
        ])
    }
}
