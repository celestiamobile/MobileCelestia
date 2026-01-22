// DistanceInputView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

@MainActor
struct DistanceInputConfiguration: UIContentConfiguration {
    struct Model: Hashable {
        let units: [String]
        var selectedUnitIndex: Int
        var distanceValue: Double?
        var distanceString: String?
    }

    var model: Model
    var directionalLayoutMargins: NSDirectionalEdgeInsets
    var unitChanged: ((Int) -> Void)?
    var distanceChanged: ((Double?, String?) -> Void)?

    init(model: Model, directionalLayoutMargins: NSDirectionalEdgeInsets = .zero, unitChanged: ((Int) -> Void)?, distanceChanged: ((Double?, String?) -> Void)?) {
        self.model = model
        self.directionalLayoutMargins = directionalLayoutMargins
        self.unitChanged = unitChanged
        self.distanceChanged = distanceChanged
    }

    func makeContentView() -> UIView & UIContentView {
        return DistanceInputView(configuration: self)
    }

    nonisolated func updated(for state: UIConfigurationState) -> DistanceInputConfiguration {
        return self
    }
}

class DistanceInputView: UIView, UIContentView {
    private lazy var distanceTextField = UITextField()
    private lazy var unitButton: UIButton = {
#if targetEnvironment(macCatalyst)
        return UIButton(type: .system)
#else
        return UIButton(configuration: .plain())
#endif
    }()

    private lazy var parseNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    private var currentConfiguration: DistanceInputConfiguration!

    var configuration: UIContentConfiguration {
        get {
            currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? DistanceInputConfiguration else {
                return
            }

            apply(configuration: newConfiguration)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(configuration: DistanceInputConfiguration) {
        super.init(frame: .zero)

        setUp()
        apply(configuration: configuration)
    }

    private func setUp() {
        unitButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        unitButton.titleLabel?.adjustsFontForContentSizeCategory = true
        unitButton.showsMenuAsPrimaryAction = true
        unitButton.changesSelectionAsPrimaryAction = true

        distanceTextField.font = UIFont.preferredFont(forTextStyle: .body)
        distanceTextField.adjustsFontForContentSizeCategory = true

        distanceTextField.translatesAutoresizingMaskIntoConstraints = false
        unitButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(distanceTextField)
        addSubview(unitButton)
        NSLayoutConstraint.activate([
            distanceTextField.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            distanceTextField.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
            distanceTextField.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),
            unitButton.leadingAnchor.constraint(equalTo: distanceTextField.trailingAnchor, constant: GlobalConstants.listItemGapHorizontal),
            unitButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            unitButton.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
            unitButton.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),
        ])

        let optionalConstraints = [
            unitButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            distanceTextField.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
        ]

        for optionalConstraint in optionalConstraints {
            optionalConstraint.priority = .defaultHigh
            optionalConstraint.isActive = true
        }

        distanceTextField.keyboardType = .decimalPad
        distanceTextField.addTarget(self, action: #selector(distanceTextChanged), for: .editingChanged)
    }

    private func apply(configuration: DistanceInputConfiguration) {
        currentConfiguration = configuration

        directionalLayoutMargins = configuration.directionalLayoutMargins
        let items = configuration.model.units.enumerated().map { (index, name) in
            return UIAction(title: name, state: index == configuration.model.selectedUnitIndex ? .on : .off) { [weak self] _ in
                guard let self = self else { return }
                self.currentConfiguration.model.selectedUnitIndex = index
                self.currentConfiguration.unitChanged?(self.currentConfiguration.model.selectedUnitIndex)
            }
        }
        unitButton.menu = UIMenu(children: items)
        distanceTextField.text = configuration.model.distanceString
    }

    @objc private func distanceTextChanged() {
        currentConfiguration.model.distanceString = distanceTextField.text
        if let text = distanceTextField.text, let value = parseNumberFormatter.number(from: text)?.doubleValue {
            currentConfiguration.model.distanceValue = value
        } else {
            currentConfiguration.model.distanceValue = nil
        }
        currentConfiguration.distanceChanged?(currentConfiguration.model.distanceValue, currentConfiguration.model.distanceString)
    }
}
