//
// LinkFooterView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import UIKit

class LinkFooterView: UITableViewHeaderFooterView {
    private var textView = UITextView()

    struct LinkInfo {
        let text: String
        let linkText: String
        let link: String
    }

    var info: LinkInfo? {
        didSet {
            updateTextView()
        }
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setUp()
        updateTextView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        textView.backgroundColor = .clear
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainerInset = UIEdgeInsets(top: 0, left: -textView.textContainer.lineFragmentPadding, bottom: 0, right: -textView.textContainer.lineFragmentPadding)
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        #if !targetEnvironment(macCatalyst)
        textView.linkTextAttributes[.foregroundColor] = UIColor.themeLabel
        #endif

        contentView.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -GlobalConstants.listItemMediumMarginVertical),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -GlobalConstants.listItemMediumMarginHorizontal)
        ])
    }

    private func updateTextView() {
        guard let info else {
            textView.text = nil
            textView.attributedText = nil
            return
        }
        let linkTextRange = (info.text as NSString).range(of: info.linkText)
        guard linkTextRange.location != NSNotFound else {
            textView.text = nil
            textView.attributedText = nil
            return
        }
        let attributedString = NSMutableAttributedString(string: info.text)
        attributedString.addAttributes([.foregroundColor: UIColor.label, .font: UIFont.preferredFont(forTextStyle: .footnote)], range: NSMakeRange(0, info.text.count))
        attributedString.addAttributes([.link: info.link], range: linkTextRange)
        textView.attributedText = attributedString
    }
}
