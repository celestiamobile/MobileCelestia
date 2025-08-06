// URL.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation

public class UniformedURL: @unchecked Sendable {
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

public extension URL {
    static func documents() -> URL? {
        return try? createDirectoryIfNeeded(for: .documentDirectory, appropriateFor: nil)
    }

    static func applicationSupport() -> URL? {
        return try? createDirectoryIfNeeded(for: .applicationSupportDirectory, appropriateFor: nil)
    }

    static func library() -> URL? {
        return try? createDirectoryIfNeeded(for: .libraryDirectory, appropriateFor: nil)
    }

    static func temp(for url: URL? = nil) throws -> URL {
        do {
            return try createDirectoryIfNeeded(for: .itemReplacementDirectory, appropriateFor: url)
        } catch {
            let fallback: URL
            if #available(iOS 16, visionOS 1, *) {
                fallback = .temporaryDirectory
            } else {
                fallback = URL(fileURLWithPath: NSTemporaryDirectory())
            }
            return try createDirectoryIfNeeded(url: fallback)
        }
    }

    private static func createDirectoryIfNeeded(for directory: FileManager.SearchPathDirectory, appropriateFor url: URL?) throws -> URL {
        let fm = FileManager.default
        return try fm.url(for: directory, in: .userDomainMask, appropriateFor: url, create: true)
    }

    private static func createDirectoryIfNeeded(url: URL) throws -> URL {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return url
        }
        do {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        } catch {
            throw error
        }
    }
}
