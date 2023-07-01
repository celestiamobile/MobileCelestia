//
// DistanceInputCell.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import UIKit

@available(iOS 15.0, *)
class DistanceInputCell: UITableViewCell {
    struct Model: Hashable {
        let units: [String]
        var selectedUnitIndex: Int
        var distance: Double
    }

    private var ignoreModelUpdates = false

    private lazy var distanceTextField = UITextField()
    private lazy var unitButton = UIButton(configuration: UIButton.Configuration.plain())
    var unitChanged: ((Int) -> Void)?
    var distanceChanged: ((Double) -> Void)?

    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var model = Model(units: [], selectedUnitIndex: -1, distance: 0) {
        didSet {
            guard !ignoreModelUpdates else { return }
            update()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update() {
        let items = model.units.enumerated().map { (index, name) in
            return UIAction(title: name, state: index == model.selectedUnitIndex ? .on : .off) { [weak self] _ in
                guard let self = self else { return }
                self.ignoreModelUpdates = true
                self.model.selectedUnitIndex = index
                self.ignoreModelUpdates = false
                self.unitChanged?(self.model.selectedUnitIndex)
            }
        }
        unitButton.menu = UIMenu(children: items)
        distanceTextField.text = numberFormatter.string(from: NSNumber(value: model.distance))
    }

    private func setUp() {
        selectionStyle = .none

        unitButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        unitButton.titleLabel?.adjustsFontForContentSizeCategory = true
        unitButton.showsMenuAsPrimaryAction = true
        unitButton.changesSelectionAsPrimaryAction = true

        distanceTextField.font = UIFont.preferredFont(forTextStyle: .body)
        distanceTextField.adjustsFontForContentSizeCategory = true

        distanceTextField.translatesAutoresizingMaskIntoConstraints = false
        unitButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(distanceTextField)
        contentView.addSubview(unitButton)
        NSLayoutConstraint.activate([
            distanceTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            distanceTextField.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
            distanceTextField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            unitButton.leadingAnchor.constraint(equalTo: distanceTextField.trailingAnchor, constant: GlobalConstants.listItemGapHorizontal),
            unitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -GlobalConstants.listItemMediumMarginHorizontal),
            unitButton.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
            unitButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        let optionalConstraints = [
            unitButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
            distanceTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
        ]

        for optionalConstraint in optionalConstraints {
            optionalConstraint.priority = .defaultHigh
            optionalConstraint.isActive = true
        }

        distanceTextField.keyboardType = .decimalPad
        distanceTextField.addTarget(self, action: #selector(distanceTextChanged), for: .editingChanged)
    }

    @objc private func distanceTextChanged() {
        if let text = distanceTextField.text, let value = numberFormatter.number(from: text)?.doubleValue ?? Double(text) {
            ignoreModelUpdates = true
            model.distance = value
            ignoreModelUpdates = false
            distanceChanged?(model.distance)
        }
    }
}
