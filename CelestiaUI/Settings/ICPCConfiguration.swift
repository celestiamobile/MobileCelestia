// ICPCConfiguration.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#if !targetEnvironment(macCatalyst)
import UIKit

@MainActor
struct ICPCConfiguration: Hashable, UIContentConfiguration {
    let text: String

    func makeContentView() -> UIView & UIContentView {
        return ICPCContentView(configuration: self)
    }

    nonisolated func updated(for state: UIConfigurationState) -> ICPCConfiguration {
        return self
    }
}

class ICPCContentView: UIView, UIContentView {
    private enum Constants {
        static let listItemMediumMarginHorizontal: CGFloat = 16
        static let listItemMediumMarginVertical: CGFloat = 12
    }

    private lazy var icpcButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .secondaryLabel
        config.titleAlignment = .center
        return UIButton(configuration: config)
    }()
    private var currentConfiguration: ICPCConfiguration!

    var configuration: UIContentConfiguration {
        get {
            currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? ICPCConfiguration else {
                return
            }

            apply(configuration: newConfiguration)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        addSubview(icpcButton)
        icpcButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icpcButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.listItemMediumMarginHorizontal),
            icpcButton.topAnchor.constraint(equalTo: topAnchor, constant: Constants.listItemMediumMarginVertical),
            icpcButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            icpcButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        icpcButton.addTarget(self, action: #selector(openICPCPage), for: .touchUpInside)
    }

    init(configuration: ICPCConfiguration) {
        super.init(frame: .zero)

        setUp()
        apply(configuration: configuration)
    }

    private func apply(configuration: ICPCConfiguration) {
        // Only apply configuration if new configuration and current configuration are not the same
        guard currentConfiguration != configuration else {
            return
        }

        currentConfiguration = configuration
        var attributedString = AttributedString(configuration.text)
        var container = AttributeContainer()
        container[AttributeScopes.UIKitAttributes.FontAttribute.self] = .preferredFont(forTextStyle: .footnote)
        attributedString.mergeAttributes(container, mergePolicy: .keepNew)
        icpcButton.configuration?.attributedTitle = attributedString
    }

    @objc private func openICPCPage() {
        guard let url = URL(string: "https://beian.miit.gov.cn") else { return }
        UIApplication.shared.open(url)
    }
}

#endif
