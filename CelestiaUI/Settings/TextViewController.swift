//
// TextViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public final class TextViewController: UIViewController {
    private let text: String

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
        view = UIView()
        #if !os(visionOS)
        view.backgroundColor = .systemBackground
        #endif
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension TextViewController {
    func setUp() {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.textColor = .label
        textView.adjustsFontForContentSizeCategory = true
        textView.font = UIFont.preferredFont(forTextStyle: .footnote)
        textView.contentInset = UIEdgeInsets(top: GlobalConstants.pageMediumMarginVertical, left: GlobalConstants.pageMediumMarginHorizontal, bottom: GlobalConstants.pageMediumMarginVertical, right: GlobalConstants.pageMediumMarginHorizontal)

        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        textView.text = text

        edgesForExtendedLayout = []
    }
}
