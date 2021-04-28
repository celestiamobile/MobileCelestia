//
// ToolbarButtonCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

protocol ToolbarCell: UICollectionViewCell {
    var itemTitle: String? { get set }
    var itemImage: UIImage? { get set }
    var actionHandler: (() -> Void)? { get set }
}

class ToolbarImageButtonCell: UICollectionViewCell, ToolbarCell {
    var itemTitle: String?
    var itemImage: UIImage? { didSet { button.setImage(itemImage, for: .normal) } }
    var actionHandler: (() -> Void)?

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

class ToolbarImageTextButtonCell: UICollectionViewCell, ToolbarCell {
    private class SelectionView: UIControl {
        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = .clear
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            UIView.animate(withDuration: 0.10) {
                self.layer.backgroundColor = UIColor.darkSelection.cgColor
            }
            return true
        }

        override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
            UIView.animate(withDuration: 0.05) {
                self.layer.backgroundColor = UIColor.clear.cgColor
            }
        }

        override func cancelTracking(with event: UIEvent?) {
            layer.backgroundColor = UIColor.clear.cgColor
        }
    }

    var itemTitle: String? { didSet { label.text = itemTitle } }
    var itemImage: UIImage? { didSet { imageView.image = itemImage?.withRenderingMode(.alwaysTemplate) } }
    var actionHandler: (() -> Void)?

    private lazy var imageView = UIImageView()
    private lazy var label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let bg = SelectionView(frame: .zero)
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        contentView.addSubview(bg)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: contentView.topAnchor),
            bg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bg.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        let ratio: CGFloat
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            ratio = 0.77
        } else {
            ratio = 1.0
        }

        bg.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 32 * ratio),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            imageView.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 16),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: bg.topAnchor, constant: 6),
        ])
        imageView.tintColor = .darkLabel

        bg.addSubview(label)
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -16),
            label.topAnchor.constraint(greaterThanOrEqualTo: bg.topAnchor, constant: 12),
        ])
        label.textColor = .darkLabel
    }

    @objc private func buttonTapped() {
        actionHandler?()
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

class ToolbarSeparatorCell: UICollectionViewCell {
    let sep = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        sep.backgroundColor = .darkSeparator
        sep.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.heightAnchor.constraint(equalToConstant: 0.5),
            sep.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
}
