//
// URL.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

public class UniformedURL {
    private let securityScoped: Bool

    public let url: URL
    public let stale: Bool

    private init?(url: URL, securityScoped: Bool, stale: Bool) {
        if securityScoped && !url.startAccessingSecurityScopedResource() {
            return nil
        }
        self.stale = stale
        self.url = url
        self.securityScoped = securityScoped
    }

    public convenience init(url: URL, securityScoped: Bool = false) {
        self.init(url: url, securityScoped: securityScoped, stale: false)!
    }

    public convenience init?(bookmark: Data) throws {
        var stale: Bool = false
        #if os(macOS) || targetEnvironment(macCatalyst)
        let resolved = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale)
        #else
        let resolved = try URL(resolvingBookmarkData: bookmark, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &stale)
        #endif
        self.init(url: resolved, securityScoped: true, stale: stale)
    }

    func bookmark() throws -> Data? {
        if !stale || !securityScoped { return nil }
        // only generate bookmark when it is stale
        let bookmark = try url.bookmarkData(options: .init(rawValue: 0), includingResourceValuesForKeys: nil, relativeTo: nil)
        return bookmark
    }

    deinit {
        if securityScoped {
            url.stopAccessingSecurityScopedResource()
        }
    }
}
