//
// SwitchCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public class SwitchCell: UITableViewCell {
    private lazy var label = UILabel(textStyle: .body)
    private lazy var subtitleLabel = UILabel(textStyle: .footnote)
    private lazy var `switch` = UISwitch()

    public var title: String? { didSet { label.text = title }  }
    public var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = subtitle == nil
        }
    }
    public var enabled: Bool = false { didSet { `switch`.isOn = enabled } }

    public var toggleBlock: ((Bool) -> Void)?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUp()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SwitchCell {
    func setUp() {
        selectionStyle = .none
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        label.textColor = .label
        label.numberOfLines = 0

        subtitleLabel.isHidden = true

        let stackView = UIStackView(arrangedSubviews: [label, subtitleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = GlobalConstants.listTextGapVertical
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
        ])

        `switch`.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(`switch`)
        NSLayoutConstraint.activate([
            `switch`.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: GlobalConstants.listItemGapHorizontal),
            `switch`.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -GlobalConstants.listItemMediumMarginHorizontal),
            `switch`.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            `switch`.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemAccessoryMinMarginVertical),
        ])
        `switch`.addTarget(self, action: #selector(handleToggle(_:)), for: .valueChanged)
    }

    @objc private func handleToggle(_ sender: UISwitch) {
        toggleBlock?(sender.isOn)
    }
}
