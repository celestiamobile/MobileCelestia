//
//  ToolbarButtonCell.swift
//  CelestiaMobile
//
//  Created by Li Linfeng on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class ToolbarButtonCell: UICollectionViewCell {
    var itemImage: UIImage? { didSet { button.setImage(itemImage, for: .normal) } }
    var actionHandler: (() -> Void)?

    private lazy var button = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        button.tintColor = .darkLabel
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc private func buttonTapped() {
        actionHandler?()
    }
}
