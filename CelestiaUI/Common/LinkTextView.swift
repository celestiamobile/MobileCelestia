//
// LinkTextView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public class LinkTextView: UIView {
    private var textView = UITextView()

    public struct Link {
        let text: String
        let link: String
    }

    public struct LinkInfo {
        let text: String
        let links: [Link]
    }

    public var info: LinkInfo? {
        didSet {
            updateTextView()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        setUp()
        updateTextView()
    }

    public required init?(coder: NSCoder) {
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

        addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func updateTextView() {
        guard let info else {
            textView.text = nil
            textView.attributedText = nil
            return
        }
        let attributedString = NSMutableAttributedString(string: info.text)
        for link in info.links {
            let linkTextRange = (info.text as NSString).range(of: link.text)
            guard linkTextRange.location != NSNotFound else {
                textView.text = nil
                textView.attributedText = nil
                return
            }
            attributedString.addAttributes([.foregroundColor: UIColor.label, .font: UIFont.preferredFont(forTextStyle: .footnote)], range: NSMakeRange(0, info.text.count))
            attributedString.addAttributes([.link: link.link], range: linkTextRange)
        }
        textView.attributedText = attributedString
    }
}
