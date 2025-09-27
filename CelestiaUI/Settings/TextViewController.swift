// TextViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

public final class TextViewController: UIViewController {
    private let text: String

    private var topMarginConstraint: NSLayoutConstraint?
    private var bottomMarginConstraint: NSLayoutConstraint?
    private var leadingMarginConstraint: NSLayoutConstraint?
    private var trailingMarginConstraint: NSLayoutConstraint?

    private lazy var scrollView = UIScrollView()

    public init(title: String, text: String) {
        self.text = text
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.windowTitle = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = scrollView
        #if !os(visionOS)
        view.backgroundColor = .systemBackground
        #endif
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    public override func updateViewConstraints() {
        let rtl = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        topMarginConstraint?.constant = GlobalConstants.pageMediumMarginVertical + view.safeAreaInsets.top
        bottomMarginConstraint?.constant = -(GlobalConstants.pageMediumMarginVertical + view.safeAreaInsets.bottom)
        leadingMarginConstraint?.constant = GlobalConstants.pageMediumMarginHorizontal + (rtl ? view.safeAreaInsets.right : view.safeAreaInsets.left)
        trailingMarginConstraint?.constant = -(GlobalConstants.pageMediumMarginHorizontal + (rtl ? view.safeAreaInsets.left : view.safeAreaInsets.right))

        super.updateViewConstraints()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        view.setNeedsUpdateConstraints()
    }
}

private extension TextViewController {
    func setUp() {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textColor = .label
        textView.font = UIFont.preferredFont(forTextStyle: .footnote)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.text = text

        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false

        topMarginConstraint = textView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor)
        bottomMarginConstraint = textView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        leadingMarginConstraint = textView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor)
        trailingMarginConstraint = textView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)

        NSLayoutConstraint.activate([
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        NSLayoutConstraint.activate([topMarginConstraint, bottomMarginConstraint, leadingMarginConstraint, trailingMarginConstraint].compactMap { $0 })
    }
}
