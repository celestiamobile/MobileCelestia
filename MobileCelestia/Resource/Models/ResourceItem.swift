//
// ResourceItem.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

struct ResourceItem: Codable {
    let name: String
    let description: String
    let id: String
    let image: URL?
    let item: URL
}
