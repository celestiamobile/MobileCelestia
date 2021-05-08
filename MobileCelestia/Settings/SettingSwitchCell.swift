//
// SettingSwitchCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class SettingSwitchCell: UITableViewCell {
    private lazy var label = UILabel()
    private lazy var `switch` = UISwitch()

    var title: String? { didSet { label.text = title }  }
    var enabled: Bool = false { didSet { `switch`.isOn = enabled } }

    var toggleBlock: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SettingSwitchCell {
    func setup() {
        selectionStyle = .none

        if #available(iOS 13.0, *) {
        } else {
            backgroundColor = .darkSecondaryBackgroundElevated
        }

        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.textColor = .darkLabel
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
        ])

        `switch`.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(`switch`)
        NSLayoutConstraint.activate([
            `switch`.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            `switch`.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            `switch`.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            `switch`.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 6),
        ])
        `switch`.addTarget(self, action: #selector(handleToggle(_:)), for: .valueChanged)
    }

    @objc private func handleToggle(_ sender: UISwitch) {
        toggleBlock?(sender.isOn)
    }
}
