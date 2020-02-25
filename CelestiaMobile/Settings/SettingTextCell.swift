//
//  SettingTextCell.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class SettingTextCell: UITableViewCell {
    private lazy var label = UILabel()

    var title: String? { didSet { label.text = title }  }

    private var savedAccessoryType: UITableViewCell.AccessoryType = .none

    override var accessoryType: UITableViewCell.AccessoryType {
        get { return savedAccessoryType }
        set {
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
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
