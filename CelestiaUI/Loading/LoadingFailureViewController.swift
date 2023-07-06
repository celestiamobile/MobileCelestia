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

import UIKit

public class LoadingFailureViewController: UIViewController {
    public override func loadView() {
        view = UIView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    private func setUp() {
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
