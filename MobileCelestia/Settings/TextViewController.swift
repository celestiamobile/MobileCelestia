//
// TextViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class TextViewController: UIViewController {
    private let text: String

    init(title: String, text: String) {
        self.text = text
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension TextViewController {
    func setup() {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.textColor = .darkLabel
        textView.adjustsFontForContentSizeCategory = true
        textView.font = UIFont.preferredFont(forTextStyle: .footnote)

        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: GlobalConstants.pageMarginHorizontal),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -GlobalConstants.pageMarginHorizontal),
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: GlobalConstants.pageMarginVertical),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -GlobalConstants.pageMarginVertical),
        ])

        textView.text = text

        edgesForExtendedLayout = []
    }
}
