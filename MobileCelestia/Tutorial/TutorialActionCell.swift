//
//  TutorialActionCell.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/3/1.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class TutorialActionCell: UITableViewCell {
    var title: String? { didSet { button.setTitle(title, for: .normal) } }
    var actionHandler: (() -> Void)?

    private lazy var button = UIButton(type: .system)

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
            button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])

        button.layer.cornerRadius = 4
        button.backgroundColor = .themeBackground
        button.setTitleColor(.darkLabel, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc private func buttonTapped() {
        actionHandler?()
    }
}

