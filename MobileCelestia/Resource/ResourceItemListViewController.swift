//
// ResourceItemListViewController.swift
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

extension ResourceItem: AsyncListItem {}

class ResourceItemListViewController: AsyncListViewController<ResourceItem> {
    private let category: ResourceCategory

    init(category: ResourceCategory, selection: @escaping (ResourceItem) -> Void) {
        self.category = category
        super.init(selection: selection)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = category.name
    }

    override func refresh(success: @escaping ([[ResourceItem]]) -> Void, failure: @escaping (Error) -> Void) {
        let requestURL = apiPrefix + "/resource/items"
        let locale = LocalizedString("LANGUAGE", "celestia")
        _ = RequestHandler.get(url: requestURL, parameters: ["lang": locale, "category": category.id], success: { (items: [ResourceItem]) in
            success([items])
        }, failure: failure, decoder: ResourceItem.networkResponseDecoder)
    }
}
