// TeachingCardView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

struct TeachingCardContentConfiguration: UIContentConfiguration {
    func updated(for state: any UIConfigurationState) -> TeachingCardContentConfiguration { self }

    func makeContentView() -> UIView & UIContentView {
        return TeachingCardContentView(configuration: self)
    }

    var title: String?
    var directionalLayoutMargins: NSDirectionalEdgeInsets
    var actionButtonTitle: String?
    var actionHandler: (() -> Void)?

    init(title: String?, directionalLayoutMargins: NSDirectionalEdgeInsets = .zero, actionButtonTitle: String?, actionHandler: (() -> Void)?) {
        self.title = title
        self.directionalLayoutMargins = directionalLayoutMargins
        self.actionButtonTitle = actionButtonTitle
        self.actionHandler = actionHandler
    }
}

class TeachingCardContentView: UIView, UIContentView {
    private var currentConfiguration: TeachingCardContentConfiguration?
    
    private lazy var titleLabel = UILabel(textStyle: .body)
    private lazy var actionButton = ActionButtonHelper.newButton(prominent: true, traitCollection: traitCollection)
    private lazy var stackView = UIStackView(arrangedSubviews: [titleLabel, actionButton])

    var configuration: UIContentConfiguration {
        get { return currentConfiguration! }
        set {
            guard let configuration = newValue as? TeachingCardContentConfiguration else {
                return
            }
            apply(configuration)
        }
    }
    
    init(configuration: TeachingCardContentConfiguration) {
        super.init(frame: .zero)
        setUp()
        apply(configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func apply(_ configuration: TeachingCardContentConfiguration) {
        currentConfiguration = configuration
        titleLabel.text = configuration.title
        titleLabel.isHidden = configuration.title == nil
        actionButton.setTitle(configuration.actionButtonTitle, for: .normal)
        actionButton.isHidden = configuration.actionButtonTitle == nil
        directionalLayoutMargins = configuration.directionalLayoutMargins
    }
    
    @objc private func buttonTapped() {
        currentConfiguration?.actionHandler?()
    }
    
    private func setUp() {
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .label
        
        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = GlobalConstants.pageMediumGapVertical
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),
        ])
    }
}
