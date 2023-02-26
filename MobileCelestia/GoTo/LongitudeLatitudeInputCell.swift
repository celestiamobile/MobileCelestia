//
// LongitudeLatitudeInputcell.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class LongitudeLatitudeInputCell: UITableViewCell {
    private lazy var longitudeTextField = UITextField()
    private lazy var latitudeTextField = UITextField()

    private lazy var longitudeLabel = UILabel(textStyle: .footnote)
    private lazy var latitudeLabel = UILabel(textStyle: .footnote)

    private var ignoreModelUpdates = false

    struct Model: Hashable {
        var longitude: Float
        var latitude: Float
    }

    var coordinatesChanged: ((Float, Float) -> Void)?

    var model = Model(longitude: 0, latitude: 0) {
        didSet {
            guard !ignoreModelUpdates else { return }
            update()
        }
    }

    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update() {
        longitudeTextField.text = numberFormatter.string(from: NSNumber(value: model.longitude))
        latitudeTextField.text = numberFormatter.string(from: NSNumber(value: model.latitude))
    }

    private func setUp() {
        selectionStyle = .none

        longitudeLabel.numberOfLines = 0
        latitudeLabel.numberOfLines = 0
        longitudeLabel.textColor = .secondaryLabel
        latitudeLabel.textColor = .secondaryLabel
        let labelStackView = UIStackView(arrangedSubviews: [longitudeLabel, latitudeLabel])
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.axis = .horizontal
        labelStackView.distribution = .fillEqually
        labelStackView.alignment = .top
        labelStackView.spacing = GlobalConstants.listItemGapHorizontal
        contentView.addSubview(labelStackView)

        longitudeLabel.text = CelestiaString("Longitude", comment: "")
        latitudeLabel.text = CelestiaString("Latitude", comment: "")

        let stackView = UIStackView(arrangedSubviews: [longitudeTextField, latitudeTextField])
        stackView.axis = .horizontal
        stackView.spacing = GlobalConstants.listItemGapHorizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            labelStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
            labelStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            labelStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: labelStackView.bottomAnchor, constant: GlobalConstants.listItemGapVertical),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -GlobalConstants.listItemMediumMarginVertical),
        ])

        longitudeTextField.font = UIFont.preferredFont(forTextStyle: .body)
        latitudeTextField.font = UIFont.preferredFont(forTextStyle: .body)
        longitudeTextField.adjustsFontForContentSizeCategory = true
        latitudeTextField.adjustsFontForContentSizeCategory = true
        longitudeTextField.keyboardType = .decimalPad
        latitudeTextField.keyboardType = .decimalPad

        longitudeTextField.addTarget(self, action: #selector(longitudeTextChanged), for: .editingChanged)
        latitudeTextField.addTarget(self, action: #selector(latitudeTextChanged), for: .editingChanged)
    }

    @objc private func longitudeTextChanged() {
        if let text = longitudeTextField.text, let value = numberFormatter.number(from: text)?.floatValue ?? Float(text) {
            ignoreModelUpdates = true
            model.longitude = value
            ignoreModelUpdates = false
            coordinatesChanged?(model.longitude, model.latitude)
        }
    }

    @objc private func latitudeTextChanged() {
        if let text = latitudeTextField.text, let value = numberFormatter.number(from: text)?.floatValue ?? Float(text) {
            ignoreModelUpdates = true
            model.latitude = value
            ignoreModelUpdates = false
            coordinatesChanged?(model.longitude, model.latitude)
        }
    }
}
