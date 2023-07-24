//
// Bundle.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

public extension Bundle {
    static let app: Bundle = {
        let current = Bundle.main
        if current.bundleURL.pathExtension == "appex" {
            #if os(macOS) || targetEnvironment(macCatalyst)
            return Bundle(url: current.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent())!
            #else
            return Bundle(url: current.bundleURL.deletingLastPathComponent().deletingLastPathComponent())!
            #endif
        }
        return current
    }()

    var shortVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var build: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}
