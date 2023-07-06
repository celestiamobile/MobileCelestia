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

extension ResourceItem: AsyncListItem, @unchecked Sendable {
    var imageURL: (URL, String)? {
        if let image = self.image {
            return (image, id)
        }
        return nil
    }
}

class InstalledResourceViewController: AsyncListViewController<ResourceItem> {
    private let resourceManager: ResourceManager

    override class var alwaysRefreshOnAppear: Bool { return true }

    init(resourceManager: ResourceManager, selection: @escaping (ResourceItem) -> Void) {
        self.resourceManager = resourceManager
        super.init(selection: selection)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = CelestiaString("Installed", comment: "")
    }

    override func loadItems(pageStart: Int, pageSize: Int) async throws -> [ResourceItem] {
        let resourceManager = self.resourceManager
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let items = resourceManager.installedResources()
                if pageStart >= items.count {
                    continuation.resume(returning: [])
                } else {
                    continuation.resume(returning: Array(items[pageStart..<min(items.count, pageStart + pageSize)]))
                }
            }
        }
    }
}
