//
// UserDefaults.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

enum UserDefaultsKey: String {
    case databaseVersion
    case dataDirPath
    case configFile
    case fullDPI
    case msaa
    #if os(iOS) || os(tvOS)
    case frameRate
    case onboardMessageDisplayed
    case lastNewsID
    #endif
}

extension UserDefaults {
    private var databaseVersion: Int { return 1 }

    private func upgrade() {
        self[.databaseVersion] = databaseVersion
    }

    fileprivate func initialize() {
        upgrade()
    }

    subscript<T>(key: UserDefaultsKey) -> T? {
        get {
            return value(forKey: key.rawValue) as? T
        }
        set {
            setValue(newValue, forKey: key.rawValue)
        }
    }
}

private struct UserDefaultsInjectionKey: InjectionKey {
    static var currentValue: UserDefaults = {
        let defaults = UserDefaults.standard
        defaults.initialize()
        return defaults
    }()
}

extension InjectedValues {
    var userDefaults: UserDefaults {
        get { Self[UserDefaultsInjectionKey.self] }
        set { Self[UserDefaultsInjectionKey.self] = newValue }
    }
}

extension UserDefaults {
    static let defaultDataDirectory: URL = {
        return Bundle.app.url(forResource: "CelestiaResources", withExtension: nil)!
    }()

    static let defaultConfigFile: URL = {
        return defaultDataDirectory.appendingPathComponent("celestia.cfg")
    }()

    static let extraDirectory: URL? = {
        let supportDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
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

    static let extraScriptDirectory: URL? = extraDirectory?.appendingPathComponent("scripts")

    private func path(for key: UserDefaultsKey, defaultValue: URL) -> UniformedURL {
        if let bookmark: Data = self[key] {
            if let url = try? UniformedURL(bookmark: bookmark) {
                if url.stale {
                    do {
                        if let newBookmark = try url.bookmark() {
                            self[key] = newBookmark
                        }
                    } catch {}
                }
                return url
            }
            return UniformedURL(url: defaultValue)
        } else if let path: String = self[key] {
            return UniformedURL(url: URL(fileURLWithPath: path))
        } else {
            return UniformedURL(url: defaultValue)
        }
    }

    func currentDataDirectory() -> UniformedURL {
        return path(for: .dataDirPath, defaultValue: Self.defaultDataDirectory)
    }

    func currentConfigFile() -> UniformedURL {
        return path(for: .configFile, defaultValue: Self.defaultConfigFile)
    }

    func saveDataDirectory(_ bookmark: Data?) {
        self[.dataDirPath] = bookmark
    }

    func saveConfigFile(_ bookmark: Data?) {
        self[.configFile] = bookmark
    }
}