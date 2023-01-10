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

import CelestiaCore
import UIKit

extension ResourceItem: AsyncListItem {
    var imageURL: (URL, String)? {
        if let image = self.image {
            return (image, id)
        }
        return nil
    }
}

class InstalledResourceViewController: AsyncListViewController<ResourceItem> {
    @Injected(\.resourceManager) private var resourceManager

    override class var alwaysRefreshOnAppear: Bool { return true }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = CelestiaString("Installed", comment: "")
    }

    override func loadItems(pageStart: Int, pageSize: Int, success: @escaping ([ResourceItem]) -> Void, failure: @escaping (Error) -> Void) {
        DispatchQueue.global().async {
            let items = self.resourceManager.installedResources()
            DispatchQueue.main.async {
                let returnItems: [ResourceItem]
                if pageStart < 0 || pageStart >= items.count || pageSize <= 0 {
                    returnItems = []
                } else {
                    returnItems = Array(items[pageStart..<min(pageStart + pageSize, items.count)])
                }
                success(returnItems)
            }
        }
    }
}
