//
//  Path.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/22.
//  Copyright © 2020 李林峰. All rights reserved.
//

import Foundation

class UniformedURL {
    private let securityScoped: Bool

    let url: URL
    let stale: Bool

    private init?(url: URL, securityScoped: Bool, stale: Bool) {
        if securityScoped && !url.startAccessingSecurityScopedResource() {
            return nil
        }
        self.stale = stale
        self.url = url
        self.securityScoped = securityScoped
    }

    convenience init(url: URL) {
        self.init(url: url, securityScoped: false, stale: false)!
    }

    convenience init?(bookmark: Data) throws {
        var stale: Bool = false
        let resolved = try URL(resolvingBookmarkData: bookmark, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &stale)
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

let defaultDataDirectory: URL = {
    return Bundle.main.url(forResource: "CelestiaResources", withExtension: nil)!
}()

let defaultConfigFile: URL = {
    return defaultDataDirectory.appendingPathComponent("celestia.cfg")
}()

let extraDirectory: URL? = {
    let supportDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0])
    let parentDirectory = supportDirectory.appendingPathComponent("CelestiaResources")
    do {
        try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true, attributes: nil)
        let extraDirectory = parentDirectory.appendingPathComponent("extras")
        try FileManager.default.createDirectory(at: extraDirectory, withIntermediateDirectories: true, attributes: nil)
        let scriptDirectory = parentDirectory.appendingPathComponent("scripts")
        try FileManager.default.createDirectory(at: scriptDirectory, withIntermediateDirectories: true, attributes: nil)
    } catch _ {
        return nil
    }
    return parentDirectory
}()

let extraScriptDirectory: URL? = extraDirectory?.appendingPathComponent("scripts")

private func path(for key: UserDefaultsKey, defaultValue: URL) -> UniformedURL {
    if let bookmark: Data = UserDefaults.app[key] {
        if let url = try? UniformedURL(bookmark: bookmark) {
            return url
        }
        return UniformedURL(url: defaultValue)
    } else if let path: String = UserDefaults.app[key] {
        return UniformedURL(url: URL(fileURLWithPath: path))
    } else {
        return UniformedURL(url: defaultValue)
    }
}

func currentDataDirectory() -> UniformedURL {
    return path(for: .dataDirPath, defaultValue: defaultDataDirectory)
}

func currentConfigFile() -> UniformedURL {
    return path(for: .configFile, defaultValue: defaultConfigFile)
}

func saveDataDirectory(_ bookmark: Data?) {
    UserDefaults.app[.dataDirPath] = bookmark
}

func saveConfigFile(_ bookmark: Data?) {
    UserDefaults.app[.configFile] = bookmark
}
