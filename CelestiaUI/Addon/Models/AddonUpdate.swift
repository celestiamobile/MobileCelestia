//
// AddonUpdate.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

public struct AddonUpdate: Codable, Hashable, Sendable {
    let checksum: String
    let size: UInt64
    let modificationDate: Date
}
