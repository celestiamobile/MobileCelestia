//
// SettingSelectionCell.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

@available(iOS 15.0, *)
class SettingSelectionCell: UITableViewCell {
    private lazy var label = UILabel(textStyle: .body)
    private lazy var button = UIButton(configuration: .plain())

    var title: String? { didSet { label.text = title }  }
    var selectionData = SelectionData(options: [], selectedIndex: -1) {
        didSet {
            reloadMenu()
        }
    }

    struct SelectionData {
        let options: [String]
        let selectedIndex: Int
    }

    var selectionChange: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 15.0, *)
private extension SettingSelectionCell {
    func setUp() {
        selectionStyle = .none

        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.textColor = .darkLabel
        label.numberOfLines = 0

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
        ])

        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: GlobalConstants.listItemGapHorizontal),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -GlobalConstants.listItemMediumMarginHorizontal),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            button.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemAccessoryMinMarginVertical),
        ])

        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func reloadMenu() {
        let actions = selectionData.options.enumerated().map { (index, title) in
            return UIAction(title: title, state: index == selectionData.selectedIndex ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.selectionChange?(index)
            }
        }
        button.menu = UIMenu(children: actions)
    }
}

