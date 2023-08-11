//
// SliderCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public class SliderCell: UITableViewCell {
    private lazy var topContainer = UIView()
    private lazy var bottomContainer = UIView()
    private lazy var label = UILabel(textStyle: .body)
    private lazy var subtitleLabel = UILabel(textStyle: .footnote)
    private lazy var slider = UISlider()

    public var title: String? { didSet { label.text = title }  }
    public var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = subtitle == nil
        }
    }

    public var value: Double = 0 { didSet { slider.value = Float(value) * 100 } }

    public var valueChangeBlock: ((Double) -> Void)?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUp()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SliderCell {
    func setUp() {
        selectionStyle = .none

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

        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.isHidden = true
        label.textColor = .label
        label.numberOfLines = 0
        let stackView = UIStackView(arrangedSubviews: [label, subtitleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = GlobalConstants.listTextGapVertical

        topContainer.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            stackView.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor, constant: -GlobalConstants.listItemMediumMarginHorizontal),
            stackView.centerYAnchor.constraint(equalTo: topContainer.centerYAnchor),
            stackView.topAnchor.constraint(equalTo: topContainer.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
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
