//
//  UserDefaults.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/29.
//  Copyright © 2020 李林峰. All rights reserved.
//

import Foundation

private var appDefaults: UserDefaults?

enum UserDefaultsKey: String {
    case databaseVersion
    case dataDirPath
    case configFile
}

extension UserDefaults {
    private var databaseVersion: Int { return 1 }

    static var app: UserDefaults {
        if appDefaults == nil {
            appDefaults = .standard
            appDefaults?.initialize()
        }
        return appDefaults!
    }

    private func upgrade() {
        self[.databaseVersion] = databaseVersion
    }

    private func initialize() {
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
