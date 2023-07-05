//
// AsyncProviderExecutor.swift
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

public protocol AsyncProviderExecutor {
    func run(_ task: @escaping @Sendable (AppCore) -> Void) async
    func get<T>(_ task: @escaping @Sendable (AppCore) -> T) async -> T
}
