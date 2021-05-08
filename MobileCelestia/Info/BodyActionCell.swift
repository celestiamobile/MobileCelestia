//
// BodyActionCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

final class BodyActionCell: UICollectionViewCell {
    var title: String? { didSet { button.setTitle(title, for: .normal) } }
    var actionHandler: ((BodyActionCell) -> Void)?

    private lazy var button = StandardButton(type: .system)

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

        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            if let uiNSView = button.subviews.first?.subviews.first,
               String(describing: type(of: uiNSView)) == "_UINSView",
               uiNSView.responds(to: NSSelectorFromString("contentNSView")) {
                let contentNSView = uiNSView.value(forKey: "contentNSView") as AnyObject
                if contentNSView.responds(to: NSSelectorFromString("setControlSize:")) {
                    contentNSView.setValue(3, forKey: "controlSize")
                }
            }
        } else {
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
            button.layer.cornerRadius = 4
            #if targetEnvironment(macCatalyst)
            button.backgroundColor = button.tintColor
            #else
            button.backgroundColor = .themeBackground
            #endif
            button.setTitleColor(.white, for: .normal)
        }
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
        attributes.size = contentView.systemLayoutSizeFitting(
            CGSize(width: layoutAttributes.size.width, height: 0),
            withHorizontalFittingPriority: UILayoutPriority.required,
            verticalFittingPriority: UILayoutPriority.defaultLow)
        return attributes
    }
}
