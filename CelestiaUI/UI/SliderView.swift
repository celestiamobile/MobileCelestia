// SliderView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

public struct SliderConfiguration: UIContentConfiguration {
    public var listContent: UIListContentConfiguration
    public var value: Double
    public var valueChanged: (Double) -> Void

    public init(listContent: UIListContentConfiguration, value: Double, valueChanged: @escaping (Double) -> Void) {
        self.listContent = listContent
        self.value = value
        self.valueChanged = valueChanged
    }

    public func makeContentView() -> any UIView & UIContentView {
        return SliderView(configuration: self)
    }
    
    public func updated(for state: any UIConfigurationState) -> SliderConfiguration {
        return self
    }
}

public class SliderView: UIView, UIContentView {
    private var currentConfiguration: SliderConfiguration!

    private let listContentView: UIListContentView
    private lazy var bottomContainer = UIView()
    private lazy var slider = UISlider()

    public var configuration: UIContentConfiguration {
        get {
            currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? SliderConfiguration else {
                return
            }

            apply(configuration: newConfiguration)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(configuration: SliderConfiguration) {
        listContentView = UIListContentView(configuration: configuration.listContent)

        super.init(frame: .zero)

        setUp()
        apply(configuration: configuration)
    }

    private func setUp() {
        addSubview(listContentView)
        listContentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomContainer)
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            listContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            listContentView.topAnchor.constraint(equalTo: topAnchor),
            listContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomContainer.topAnchor.constraint(equalTo: listContentView.bottomAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            slider.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            slider.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -GlobalConstants.listItemMediumMarginHorizontal),
            slider.topAnchor.constraint(equalTo: bottomContainer.topAnchor),
            slider.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor, constant: -GlobalConstants.listItemMediumMarginVertical),
        ])
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(handleSlideEnd(_:)), for: .touchCancel)
    }

    private func apply(configuration: SliderConfiguration) {
        currentConfiguration = configuration
        listContentView.configuration = configuration.listContent
        slider.value = Float(configuration.value) * 100
    }

    @objc private func handleSlideEnd(_ sender: UISlider) {
        currentConfiguration.valueChanged(Double(sender.value / 100))
    }
}
