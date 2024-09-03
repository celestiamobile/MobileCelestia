//
// URL.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

public extension URL {
    private static let apiPrefix = "https://celestia.mobi/api"

    static func fromGuide(guideItemID: String, language: String, shareable: Bool? = nil) -> URL {
        let baseURL = "https://celestia.mobi/resources/guide"
        var components = URLComponents(string: baseURL)!
        #if os(visionOS)
        let platform = "visionos"
        #else
        #if targetEnvironment(macCatalyst)
        let platform = "catalyst"
        #else
        let platform = "ios"
        #endif
        #endif
        var queryItems = [
            URLQueryItem(name: "guide", value: guideItemID),
            URLQueryItem(name: "lang", value: language),
            URLQueryItem(name: "platform", value: platform),
            URLQueryItem(name: "theme", value: "dark")
        ]
        if let shareable = shareable {
            queryItems.append(URLQueryItem(name: "share", value: shareable ? "true" : "false"))
        }
        components.queryItems = queryItems
        return components.url!
    }

    static func fromGuideShort(path: String, language: String, shareable: Bool? = nil) -> URL {
        let baseURL = "https://celestia.mobi"
        var components = URLComponents(string: baseURL)!
        components.path = path
        #if os(visionOS)
        let platform = "visionos"
        #else
        #if targetEnvironment(macCatalyst)
        let platform = "catalyst"
        #else
        let platform = "ios"
        #endif
        #endif
        var queryItems = [
            URLQueryItem(name: "lang", value: language),
            URLQueryItem(name: "platform", value: platform),
            URLQueryItem(name: "theme", value: "dark")
        ]
        if let shareable = shareable {
            queryItems.append(URLQueryItem(name: "share", value: shareable ? "true" : "false"))
        }
        components.queryItems = queryItems
        return components.url!
    }

    static func fromAddon(addonItemID: String, language: String) -> URL {
        let baseURL = "https://celestia.mobi/resources/item"
        var components = URLComponents(string: baseURL)!
        #if os(visionOS)
        let platform = "visionos"
        #else
        #if targetEnvironment(macCatalyst)
        let platform = "catalyst"
        #else
        let platform = "ios"
        #endif
        #endif
        components.queryItems = [
            URLQueryItem(name: "item", value: addonItemID),
            URLQueryItem(name: "lang", value: language),
            URLQueryItem(name: "platform", value: platform),
            URLQueryItem(name: "theme", value: "dark"),
            URLQueryItem(name: "titleVisibility", value: "collapsed"),
        ]
        return components.url!
    }

    static func fromAddonForSharing(addonItemID: String, language: String) -> URL {
        let baseURL = "https://celestia.mobi/resources/item"
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "item", value: addonItemID),
            URLQueryItem(name: "lang", value: language),
        ]
        return components.url!
    }

    static let addonMetadata = URL(string: apiPrefix)!.appendingPathComponent("resource/item")
    static let latestGuideMetadata = URL(string: apiPrefix)!.appendingPathComponent("resource/latest")
}
