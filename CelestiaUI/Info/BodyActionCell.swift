// BodyActionCell.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

final class BodyActionCell: UICollectionViewCell {
    var title: String? { didSet { button.setTitle(title, for: .normal) } }
    var menu: UIMenu? {
        didSet {
            if let menu = menu {
                button.menu = menu
                button.showsMenuAsPrimaryAction = true
            } else {
                button.menu = nil
                button.showsMenuAsPrimaryAction = false
            }
        }
    }
    var actionHandler: ((BodyActionCell) -> Void)?

    private lazy var button = ActionButtonHelper.newButton(liquidGlass: false, traitCollection: traitCollection)

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
        actionHandler?(self)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let fittingSize = contentView.systemLayoutSizeFitting(
            CGSize(width: layoutAttributes.size.width, height: 0),
            withHorizontalFittingPriority: UILayoutPriority.required,
            verticalFittingPriority: UILayoutPriority.defaultLow)
        let height: CGFloat
        if traitCollection.userInterfaceIdiom == .mac {
            height = fittingSize.height
        } else {
            height = max(fittingSize.height, layoutAttributes.size.height)
        }
        attributes.size = CGSize(width: fittingSize.width, height: height)
        return attributes
    }
}
