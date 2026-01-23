//
// BottomToolbarImageButtonCell.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import UIKit

class BottomToolbarImageButtonCell: UICollectionViewCell {
    var itemTitle: String?
    var itemImage: UIImage? { didSet { button.configuration?.image = itemImage } }
    var itemAccessibilityLabel: String? { didSet { button.accessibilityLabel = itemAccessibilityLabel } }
    var menu: UIMenu? { didSet { button.showsMenuAsPrimaryAction = menu != nil; button.menu = menu } }
    var touchDownHandler: ((UIControl) -> Void)?
    var touchUpHandler: ((UIControl, Bool) -> Void)?

    private lazy var button = StandardButton(configuration: .plain())

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        button.tintColor = .label
        let padding = GlobalConstants.preferredUIElementScaling(for: traitCollection) * GlobalConstants.bottomControlViewItemPadding
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
        button.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(textStyle: .title3)
        button.adjustsImageSizeForAccessibilityContentSizeCategory = true
        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            button.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            button.heightAnchor.constraint(equalTo: contentView.heightAnchor),
        ])
        button.addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(touchUpOutside(_:)), for: .touchUpOutside)
        button.addTarget(self, action: #selector(touchCancelled(_:)), for: .touchCancel)
    }

    @objc private func touchDown(_ sender: UIButton) {
        touchDownHandler?(sender)
    }

    @objc private func touchUpInside(_ sender: UIButton) {
        touchUpHandler?(sender, true)
    }

    @objc private func touchUpOutside(_ sender: UIButton) {
        touchUpHandler?(sender, false)
    }

    @objc private func touchCancelled(_ sender: UIButton) {
        touchUpHandler?(sender, false)
    }
}
