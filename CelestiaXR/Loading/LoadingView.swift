//
// LoadingView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import SwiftUI

struct LoadingView: UIViewControllerRepresentable {
    typealias UIViewControllerType = LoadingViewController

    let currentFile: String?

    func makeUIViewController(context: Context) -> LoadingViewController {
        let vc = LoadingViewController()
        if let currentFile {
            vc.update(with: currentFile)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: LoadingViewController, context: Context) {
        if let currentFile {
            uiViewController.update(with: currentFile)
        }
    }
}
