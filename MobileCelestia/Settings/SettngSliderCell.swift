//
// SettngSliderCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import UIKit

class SettingSliderCell: UITableViewCell {
    private lazy var topContainer = UIView()
    private lazy var bottomContainer = UIView()
    private lazy var label = UILabel(textStyle: .body)
    private lazy var slider = UISlider()

    var title: String? { didSet { label.text = title }  }
    var value: Double = 0 { didSet { slider.value = Float(value) * 100 } }

    var valueChangeBlock: ((Double) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SettingSliderCell {
    func setup() {
        selectionStyle = .none

        if #available(iOS 13.0, *) {
        } else {
            backgroundColor = .darkSecondaryBackground
        }

        topContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(topContainer)
        contentView.addSubview(bottomContainer)

        NSLayoutConstraint.activate([
            topContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            topContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomContainer.topAnchor.constraint(equalTo: topContainer.bottomAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        label.translatesAutoresizingMaskIntoConstraints = false
        topContainer.addSubview(label)
        label.textColor = .darkLabel
        label.numberOfLines = 0

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            label.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor, constant: -GlobalConstants.listItemMediumMarginHorizontal),
            label.centerYAnchor.constraint(equalTo: topContainer.centerYAnchor),
            label.topAnchor.constraint(equalTo: topContainer.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
        ])

        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(slider)
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            slider.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -GlobalConstants.listItemMediumMarginHorizontal),
            slider.topAnchor.constraint(equalTo: bottomContainer.topAnchor),
            slider.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor, constant: -GlobalConstants.listItemMediumMarginVertical),
        ])
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchCancel)
    }

    @objc private func handleSlideEnd(_ sender: UISlider) {
        valueChangeBlock?(Double(sender.value / 100))
    }
}
