// LinkTextView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

@MainActor
struct LinkTextConfiguration: UIContentConfiguration {
    struct Link: Hashable {
        let text: String
        let link: String
    }

    struct LinkInfo: Hashable {
        let text: String
        let links: [Link]
    }

    var info: LinkInfo
    var directionalLayoutMargins: NSDirectionalEdgeInsets

    init(info: LinkInfo, directionalLayoutMargins: NSDirectionalEdgeInsets = .zero) {
        self.info = info
        self.directionalLayoutMargins = directionalLayoutMargins
    }

    func makeContentView() -> UIView & UIContentView {
        return LinkTextView(configuration: self)
    }

    nonisolated func updated(for state: UIConfigurationState) -> LinkTextConfiguration {
        return self
    }
}

class LinkTextView: UIView, UIContentView {
    private var textView = UITextView()

    private var currentConfiguration: LinkTextConfiguration!

    var configuration: UIContentConfiguration {
        get {
            currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? LinkTextConfiguration else {
                return
            }

            apply(configuration: newConfiguration)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(configuration: LinkTextConfiguration) {
        super.init(frame: .zero)

        setUp()
        apply(configuration: configuration)
    }

    private func setUp() {
        textView.backgroundColor = .clear
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainer.lineBreakMode = .byWordWrapping

        addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
    }

    private func apply(configuration: LinkTextConfiguration) {
        currentConfiguration = configuration
        directionalLayoutMargins = configuration.directionalLayoutMargins
        let attributedString = NSMutableAttributedString(string: configuration.info.text)
        for link in configuration.info.links {
            let linkTextRange = (configuration.info.text as NSString).range(of: link.text)
            guard linkTextRange.location != NSNotFound else {
                textView.text = nil
                textView.attributedText = nil
                return
            }
            attributedString.addAttributes([.foregroundColor: UIColor.secondaryLabel, .font: UIFont.preferredFont(forTextStyle: .footnote)], range: NSMakeRange(0, configuration.info.text.count))
            attributedString.addAttributes([.link: link.link], range: linkTextRange)
        }
        textView.attributedText = attributedString
    }
}
