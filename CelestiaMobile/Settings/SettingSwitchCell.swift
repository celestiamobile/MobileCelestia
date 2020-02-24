//
//  SettingSwitchCell.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
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

        backgroundColor = .darkSecondaryBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .darkSelection
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.textColor = .darkLabel

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        `switch`.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(`switch`)
        NSLayoutConstraint.activate([
            `switch`.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            `switch`.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            `switch`.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        `switch`.addTarget(self, action: #selector(handleToggle(_:)), for: .valueChanged)
    }

    @objc private func handleToggle(_ sender: UISwitch) {
        toggleBlock?(sender.isOn)
    }
}
