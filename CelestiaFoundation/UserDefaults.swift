//
// UserDefaults.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

public enum UserDefaultsKey: String, Sendable {
    case databaseVersion

    case onboardMessageDisplayed
    case lastNewsID

    case gameControllerRemapA
    case gameControllerRemapB
    case gameControllerRemapX
    case gameControllerRemapY
    case gameControllerRemapLT
    case gameControllerRemapRT
    case gameControllerRemapLB
    case gameControllerRemapRB
    case gameControllerRemapDpadLeft
    case gameControllerRemapDpadRight
    case gameControllerRemapDpadUp
    case gameControllerRemapDpadDown
    case gameControllerInvertX
    case gameControllerInvertY
    case gameControllerLeftThumbstickEnabled
    case gameControllerRightThumbstickEnabled

    case normalFontPath
    case normalFontIndex
    case boldFontPath
    case boldFontIndex

    case pickSensitivity

    #if !os(visionOS)
    case fullDPI
    #else
    case foveatedRendering
    #endif
    case msaa
    #if !os(visionOS)
    case toolbarItems
    case frameRate
    case dataDirPath
    case configFile
    #if targetEnvironment(macCatalyst)
    case pinchZoom
    #else
    case contextMenu
    #endif
    #endif
}

public extension UserDefaults {
    subscript<T>(key: UserDefaultsKey) -> T? {
        get {
            return value(forKey: key.rawValue) as? T
        }
        set {
            setValue(newValue, forKey: key.rawValue)
        }
    }
}

public extension UserDefaults {
    func url(for key: String, defaultValue: URL) -> UniformedURL {
        if let bookmark = self.value(forKey: key) as? Data {
            if let url = try? UniformedURL(bookmark: bookmark) {
                if url.stale {
                    do {
                        if let newBookmark = try url.bookmark() {
                            setValue(newBookmark, forKey: key)
                        }
                    } catch {}
                }
                return url
            }
            return UniformedURL(url: defaultValue)
        } else if let path = self.value(forKey: key) as? String {
            return UniformedURL(url: URL(fileURLWithPath: path))
        } else {
            return UniformedURL(url: defaultValue)
        }
    }
}

extension UserDefaults: @unchecked @retroactive Sendable {}
