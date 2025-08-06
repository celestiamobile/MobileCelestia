// ResourceItem.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation

public struct ResourceItem: Codable {
    public let name: String
    let description: String
    let type: String?
    public let id: String
    let image: URL?
    let item: URL
    let authors: [String]?
    let publishTime: Date?
    let objectName: String?
    let mainScriptName: String?

    public static let networkResponseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
}
