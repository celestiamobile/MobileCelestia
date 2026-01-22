// LongitudeLatitudeInputView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

@MainActor
struct LongitudeLatitudeInputConfiguration: UIContentConfiguration {
    struct Model: Hashable {
        var longitude: Float?
        var latitude: Float?
        var longitudeString: String?
        var latitudeString: String?
    }

    var model: Model
    var directionalLayoutMargins: NSDirectionalEdgeInsets
    var coordinatesChanged: ((Float?, Float?, String?, String?) -> Void)?

    init(model: Model, directionalLayoutMargins: NSDirectionalEdgeInsets = .zero, coordinatesChanged: ((Float?, Float?, String?, String?) -> Void)?) {
        self.model = model
        self.directionalLayoutMargins = directionalLayoutMargins
        self.coordinatesChanged = coordinatesChanged
    }

    func makeContentView() -> UIView & UIContentView {
        return LongitudeLatitudeInputView(configuration: self)
    }

    nonisolated func updated(for state: UIConfigurationState) -> LongitudeLatitudeInputConfiguration {
        return self
    }
}

class LongitudeLatitudeInputView: UIView, UIContentView {
    private lazy var longitudeTextField = UITextField()
    private lazy var latitudeTextField = UITextField()

    private lazy var longitudeLabel = UILabel(textStyle: .footnote)
    private lazy var latitudeLabel = UILabel(textStyle: .footnote)

    private lazy var parseNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    private var currentConfiguration: LongitudeLatitudeInputConfiguration!

    var configuration: UIContentConfiguration {
        get {
            currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? LongitudeLatitudeInputConfiguration else {
                return
            }

            apply(configuration: newConfiguration)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(configuration: LongitudeLatitudeInputConfiguration) {
        super.init(frame: .zero)

        setUp()
        apply(configuration: configuration)
    }

    private func setUp() {

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
        addSubview(labelStackView)

        longitudeLabel.text = CelestiaString("Longitude", comment: "Coordinates")
        latitudeLabel.text = CelestiaString("Latitude", comment: "Coordinates")

        let stackView = UIStackView(arrangedSubviews: [latitudeTextField, longitudeTextField])
        stackView.axis = .horizontal
        stackView.spacing = GlobalConstants.listItemGapHorizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        addSubview(stackView)

        NSLayoutConstraint.activate([
            labelStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            labelStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            labelStackView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: labelStackView.bottomAnchor, constant: GlobalConstants.listItemGapVertical),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
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

    private func apply(configuration: LongitudeLatitudeInputConfiguration) {
        currentConfiguration = configuration
        directionalLayoutMargins = configuration.directionalLayoutMargins
        longitudeTextField.text = configuration.model.longitudeString
        latitudeTextField.text = configuration.model.latitudeString
    }

    @objc private func longitudeTextChanged() {
        currentConfiguration.model.longitudeString = longitudeTextField.text
        if let text = longitudeTextField.text, let value = parseNumberFormatter.number(from: text)?.floatValue, value >= -180.0, value <= 180.0 {
            currentConfiguration.model.longitude = value
        } else {
            currentConfiguration.model.longitude = nil
        }
        currentConfiguration.coordinatesChanged?(currentConfiguration.model.longitude, currentConfiguration.model.latitude, currentConfiguration.model.longitudeString, currentConfiguration.model.latitudeString)
    }

    @objc private func latitudeTextChanged() {
        currentConfiguration.model.latitudeString = latitudeTextField.text
        if let text = latitudeTextField.text, let value = parseNumberFormatter.number(from: text)?.floatValue, value >= -90.0, value <= 90.0 {
            currentConfiguration.model.latitude = value
        } else {
            currentConfiguration.model.latitude = nil
        }
        currentConfiguration.coordinatesChanged?(currentConfiguration.model.longitude, currentConfiguration.model.latitude, currentConfiguration.model.longitudeString, currentConfiguration.model.latitudeString)
    }
}
