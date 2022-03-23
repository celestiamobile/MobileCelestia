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
    private var savedItems: [ResourceItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CelestiaString("Installed", comment: "")
    }

    override func loadItems(pageStart: Int, pageSize: Int, success: @escaping ([ResourceItem]) -> Void, failure: @escaping (Error) -> Void) {
        if !savedItems.isEmpty {
            success(getItemsForRange(pageStart: pageStart, pageSize: pageSize))
            return
        }
        DispatchQueue.global().async {
            let items = ResourceManager.shared.installedResources()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.savedItems = items
                success(self.getItemsForRange(pageStart: pageStart, pageSize: pageSize))
            }
        }
    }

    private func getItemsForRange(pageStart: Int, pageSize: Int) -> [ResourceItem] {
        if pageStart < 0 || pageStart >= savedItems.count || pageSize <= 0 {
            return []
        }
        return Array(savedItems[pageStart..<min(pageStart + pageSize, savedItems.count)])
    }
}
