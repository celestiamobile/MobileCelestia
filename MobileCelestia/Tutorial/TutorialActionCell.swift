//
// TutorialActionCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class TutorialActionCell: UITableViewCell {
    private enum Constants {
        static let iconDimension: CGFloat = 44
        static let gapHorizontal: CGFloat = 16
    }

    var title: String? { didSet { button.setTitle(title, for: .normal) } }
    var actionHandler: (() -> Void)?

    private lazy var button = ActionButtonHelper.newButton()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TutorialActionCell {
    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GlobalConstants.listTextGapVertical),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -GlobalConstants.listTextGapVertical),
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMarginHorizontal),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -GlobalConstants.listItemMarginHorizontal),
        ])

        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc private func buttonTapped() {
        actionHandler?()
    }
}

