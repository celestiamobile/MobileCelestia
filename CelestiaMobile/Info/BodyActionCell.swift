//
//  BodyActionCell.swift
//  TestViewController
//
//  Created by Li Linfeng on 2020/2/24.
//  Copyright © 2020 Li Linfeng. All rights reserved.
//

import UIKit

final class BodyActionCell: UICollectionViewCell {
    var title: String? { didSet { button.setTitle(title, for: .normal) } }
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
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc private func buttonTapped() {
        actionHandler?()
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        attributes.size = CGSize(width: layoutAttributes.size.width, height: 50)
        return attributes
    }
}
