//
// BrowserItemStore.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import Foundation

@Observable class BrowserItemStore {
    private var items: [UUID: BrowserItem] = [:]

    func getItem(by id: UUID) -> BrowserItem? {
        return items[id]
    }

    func save(item: BrowserItem) -> UUID? {
        guard let entry = item.entry else {
            return nil
        }
        let selection = Selection(object: entry)
        if let existing = items.first(where: {
            guard let entry = $0.value.entry else {
                return false
            }
            return selection.isEqual(to: Selection(object: entry))
        }) {
            return existing.key
        }
        let id = UUID()
        items[id] = item
        return id
    }
}
