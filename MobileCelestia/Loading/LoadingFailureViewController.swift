//
// LoadingFailureViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import UIKit

class LoadingFailureViewController: UIViewController {

    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    private func setup() {
        let label = UILabel(textStyle: .body)
        view.addSubview(label)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            [
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ]
        )

        label.text = CelestiaString("Loading Celestia failed…", comment: "")
    }
}
