//
// RequestHandler.swift
//
// Copyright © 2024 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

public protocol RequestHandler: Sendable {
    func getMetadata(id: String, language: String) async throws -> ResourceItem
    func getSubscriptionValidity(originalTransactionID: UInt64, sandbox: Bool) async throws -> Bool
}
