//
// TeachingCardCell.swift
//
// Copyright © 2024 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class TeachingCardCell: UITableViewHeaderFooterView {
    var teachingCard = TeachingCardView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        teachingCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(teachingCard)

        NSLayoutConstraint.activate([
            teachingCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UITableView.Style.defaultGrouped == .grouped ? GlobalConstants.listItemMediumMarginHorizontal : 0),
            teachingCard.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            teachingCard.topAnchor.constraint(equalTo: contentView.topAnchor),
            teachingCard.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
