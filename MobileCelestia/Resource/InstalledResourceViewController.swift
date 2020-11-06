//
// InstalledResourceViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

import CelestiaCore

class InstalledResourceViewController: AsyncListViewController<ResourceItem> {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = CelestiaString("Installed", comment: "")
    }

    override func refresh(success: @escaping ([[ResourceItem]]) -> Void, failure: @escaping (Error) -> Void) {
        DispatchQueue.global().async {
            let items = ResourceManager.shared.installedResources()
            DispatchQueue.main.async {
                success([items])
            }
        }
    }
}
