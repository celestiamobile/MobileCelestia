//
// SettingStepperCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class SettingStepperCell: UITableViewCell {
    private lazy var label = UILabel()
    private lazy var stepper = UIStepper()

    var title: String? { didSet { label.text = title }  }

    var changeBlock: ((Bool) -> Void)?
    var stopBlock: (() -> Void)?

    private enum Button {
        case plus
        case minus
    }

    private var stepperValue: Double = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SettingStepperCell {
    func setup() {
        selectionStyle = .none

        if #available(iOS 13.0, *) {
        } else {
            backgroundColor = .darkSecondaryBackground
        }

        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.textColor = .darkLabel
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0

        stepper.wraps = true

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
        ])

        stepper.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stepper)
        NSLayoutConstraint.activate([
            stepper.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            stepper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stepper.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stepper.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 6),
        ])
        stepperValue = stepper.value
        stepper.addTarget(self, action: #selector(handleChange(_:)), for: .valueChanged)
        stepper.addTarget(self, action: #selector(handleTouchUp(_:)), for: .touchUpInside)
        stepper.addTarget(self, action: #selector(handleTouchUp(_:)), for: .touchUpOutside)
        stepper.addTarget(self, action: #selector(handleTouchUp(_:)), for: .touchCancel)
    }

    @objc private func handleChange(_ sender: UIStepper) {
        let orig = stepperValue
        let newValue = sender.value
        var isPlus = orig < newValue
        var isMinus = orig > newValue
        if sender.wraps {
            if orig > sender.maximumValue - sender.stepValue {
                isPlus = newValue < sender.minimumValue + sender.stepValue
                isMinus = isMinus && !isPlus
            } else if orig < sender.minimumValue + sender.stepValue {
                isMinus = newValue > sender.maximumValue - sender.stepValue
                isPlus = isPlus && !isMinus
            }
        }
        stepperValue = sender.value
        changeBlock?(isPlus)
    }

    @objc private func handleTouchUp(_ sender: UIStepper) {
        stopBlock?()
    }
}
