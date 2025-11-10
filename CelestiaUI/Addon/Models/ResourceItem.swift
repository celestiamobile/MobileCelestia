// ResourceItem.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation
import MWRequest

public struct ResourceItem: Codable, JSONDecodable {
    public static let decoder: JSONDecoder? = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    public let name: String
    let description: String
    let type: String?
    public let id: String
    let image: URL?
    let item: URL
    let checksum: String?
    let authors: [String]?
    let publishTime: Date?
    let objectName: String?
    let mainScriptName: String?
}
