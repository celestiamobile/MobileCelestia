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

import CelestiaFoundation
import Foundation

extension UserDefaults {
    private var databaseVersion: Int { return 1 }

    private func upgrade() {
        self[.databaseVersion] = databaseVersion
    }

    func initialize() {
        upgrade()
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
        guard let supportDirectory = URL.documents() else { return nil }
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

    static let extraAddonDirectory: URL? = extraDirectory?.appendingPathComponent("extras")
    static let extraScriptDirectory: URL? = extraDirectory?.appendingPathComponent("scripts")

    func currentDataDirectory() -> UniformedURL {
        return url(for: UserDefaultsKey.dataDirPath.rawValue, defaultValue: Self.defaultDataDirectory)
    }

    func currentConfigFile() -> UniformedURL {
        return url(for: UserDefaultsKey.configFile.rawValue, defaultValue: Self.defaultConfigFile)
    }

    func saveDataDirectory(_ bookmark: Data?) {
        self[.dataDirPath] = bookmark
    }

    func saveConfigFile(_ bookmark: Data?) {
        self[.configFile] = bookmark
    }
}
