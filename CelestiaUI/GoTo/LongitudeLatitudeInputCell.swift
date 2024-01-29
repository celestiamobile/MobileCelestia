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
        var longitude: Float?
        var latitude: Float?
        var longitudeString: String?
        var latitudeString: String?
    }

    var coordinatesChanged: ((Float?, Float?, String?, String?) -> Void)?

    var model = Model(longitude: 0, latitude: 0) {
        didSet {
            guard !ignoreModelUpdates else { return }
            update()
        }
    }

    private lazy var parseNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
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
        longitudeTextField.text = model.longitudeString
        latitudeTextField.text = model.latitudeString
    }

    private func setUp() {
        selectionStyle = .none

        longitudeLabel.numberOfLines = 0
        latitudeLabel.numberOfLines = 0
        longitudeLabel.textColor = .secondaryLabel
        latitudeLabel.textColor = .secondaryLabel
        let labelStackView = UIStackView(arrangedSubviews: [latitudeLabel, longitudeLabel])
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.axis = .horizontal
        labelStackView.distribution = .fillEqually
        labelStackView.alignment = .top
        labelStackView.spacing = GlobalConstants.listItemGapHorizontal
        contentView.addSubview(labelStackView)

        longitudeLabel.text = CelestiaString("Longitude", comment: "Coordinates")
        latitudeLabel.text = CelestiaString("Latitude", comment: "Coordinates")

        let stackView = UIStackView(arrangedSubviews: [latitudeTextField, longitudeTextField])
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
        ignoreModelUpdates = true
        model.longitudeString = longitudeTextField.text
        if let text = longitudeTextField.text, let value = parseNumberFormatter.number(from: text)?.floatValue, value >= -180.0, value <= 180.0 {
            model.longitude = value
        } else {
            model.longitude = nil
        }
        ignoreModelUpdates = false
        coordinatesChanged?(model.longitude, model.latitude, model.longitudeString, model.latitudeString)
    }

    @objc private func latitudeTextChanged() {
        ignoreModelUpdates = true
        model.latitudeString = latitudeTextField.text
        if let text = latitudeTextField.text, let value = parseNumberFormatter.number(from: text)?.floatValue, value >= -90.0, value <= 90.0 {
            model.latitude = value
        } else {
            model.latitude = nil
        }
        ignoreModelUpdates = false
        coordinatesChanged?(model.longitude, model.latitude, model.longitudeString, model.latitudeString)
    }
}
