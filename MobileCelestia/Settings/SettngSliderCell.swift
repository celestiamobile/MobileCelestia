//
//  SettingSliderCell.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class SettingSliderCell: UITableViewCell {
    private lazy var topContainer = UIView()
    private lazy var bottomContainer = UIView()
    private lazy var label = UILabel()
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

        backgroundColor = .darkSecondaryBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .darkSelection

        topContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(topContainer)
        contentView.addSubview(bottomContainer)

        NSLayoutConstraint.activate([
            topContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            topContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topContainer.heightAnchor.constraint(equalToConstant: 44),
            bottomContainer.topAnchor.constraint(equalTo: topContainer.bottomAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        label.translatesAutoresizingMaskIntoConstraints = false
        topContainer.addSubview(label)
        label.textColor = .darkLabel

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: topContainer.centerYAnchor)
        ])

        slider.minimumTrackTintColor = .darkSliderMinimumTrackTintColor
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(slider)
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -16),
            slider.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor)
        ])
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchCancel)
    }

    @objc private func handleSlideEnd(_ sender: UISlider) {
        valueChangeBlock?(Double(sender.value / 100))
    }
}
