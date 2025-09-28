// TeachingCardView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

struct TeachingCardContentConfiguration: UIContentConfiguration, Hashable {
    func updated(for state: any UIConfigurationState) -> TeachingCardContentConfiguration { self }

    func makeContentView() -> UIView & UIContentView {
        return TeachingCardContentView(configuration: self)
    }

    var title: String?
    var actionButtonTitle: String?

    init(title: String?, actionButtonTitle: String?) {
        self.title = title
        self.actionButtonTitle = actionButtonTitle
    }
}

class TeachingCardContentView: UIView, UIContentView {
    private var currentConfiguration: TeachingCardContentConfiguration?

    private lazy var titleLabel = UILabel(textStyle: .body)
    private lazy var actionButton = ActionButtonHelper.newButton(prominent: true, traitCollection: traitCollection)
    private lazy var stackView = UIStackView(arrangedSubviews: [titleLabel, actionButton])

    var actionButtonTapped: (() -> Void)?
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
        guard currentConfiguration != configuration else { return }

        currentConfiguration = configuration
        titleLabel.text = configuration.title
        titleLabel.isHidden = configuration.title == nil
        actionButton.setTitle(configuration.actionButtonTitle, for: .normal)
        actionButton.isHidden = configuration.actionButtonTitle == nil
    }

    @objc private func buttonTapped() {
        actionButtonTapped?()
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
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}

class TeachingCardView: UIView {
    var actionButtonTapped: (() -> Void)? = nil
    var contentConfiguration: UIContentConfiguration? {
        didSet {
            update(oldConfiguration: oldValue, newConfiguration: contentConfiguration)
        }
    }

    private var currentContentView: UIView?
    private lazy var container = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerRadius = GlobalConstants.cardCornerRadius
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerCurve = .continuous
        addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        update(oldConfiguration: nil, newConfiguration: nil)
    }

    convenience init(title: String?, actionButtonTitle: String?) {
        self.init()
        update(oldConfiguration: nil, newConfiguration: TeachingCardContentConfiguration(title: title, actionButtonTitle: actionButtonTitle))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(oldConfiguration: UIContentConfiguration?, newConfiguration: UIContentConfiguration?) {
        if let currentContent = currentContentView as? UIContentView, let old = oldConfiguration, let new = newConfiguration {
            if type(of: old) == type(of: new) {
                currentContent.configuration = new
                return
            }
        }

        let contentView: UIView
        if let view = newConfiguration?.makeContentView() {
            contentView = view
        } else {
            let view = UIView()
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: 0),
                view.heightAnchor.constraint(equalToConstant: 0),
            ])
            contentView = view
        }

        currentContentView?.removeFromSuperview()

        contentView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: GlobalConstants.cardContentPadding),
            contentView.topAnchor.constraint(equalTo: container.topAnchor, constant: GlobalConstants.cardContentPadding),
            contentView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        if let view = contentView as? TeachingCardContentView {
            view.actionButtonTapped = { [weak self] in
                guard let self else { return }
                self.actionButtonTapped?()
            }
        }

        currentContentView = contentView
    }
}
