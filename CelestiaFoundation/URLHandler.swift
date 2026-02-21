//
// URLHandler.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation
import UIKit

@MainActor public enum WindowURL: Codable, Hashable, Sendable {
    case addon(id: String)
    case guide(id: String)
    case object(path: String, action: ObjectURLAction?)
}

@MainActor public enum ObjectURLAction: String, Codable, Hashable, Sendable {
    case select
    case go
    case center
    case follow
    case chase
    case track
    case syncOrbit
    case lock
    case land
}

@MainActor public enum AppURL: Codable, Hashable, Sendable {
    case celScript(url: URL)
    case celURL(url: URL)
    case windowURL(url: WindowURL, universal: Bool)

    public static func from(urlContext: UIOpenURLContext) -> AppURL? {
        return from(url: urlContext.url, openInPlace: urlContext.url.isFileURL && urlContext.options.openInPlace)
    }

    public static func from(url: URL, openInPlace: Bool) -> AppURL? {
        var appURL: AppURL?
        if url.isFileURL {
            if openInPlace {
                if url.startAccessingSecurityScopedResource() {
                    if let tempDirectory = try? URL.temp(for: url) {
                        var tempURL = tempDirectory.appendingPathComponent(UUID().uuidString)
                        let fileExtension = url.pathExtension
                        if !fileExtension.isEmpty {
                            tempURL = tempURL.appendingPathExtension(fileExtension)
                        }
                        do {
                            try FileManager.default.copyItem(at: url, to: tempURL)
                            appURL = .celScript(url: tempURL)
                        } catch {}
                    }
                    url.stopAccessingSecurityScopedResource()
                }
            } else {
                appURL = .celScript(url: url)
            }
        } else if url.scheme == "cel" {
            appURL = .celURL(url: url)
        } else if url.scheme == "celaddon" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               components.host == "item",
               let id = components.queryItems?.first(where: { $0.name == "item" })?.value {
                appURL = .windowURL(url: .addon(id: id), universal: false)
            }
        } else if url.scheme == "celguide" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               components.host == "guide",
               let id = components.queryItems?.first(where: { $0.name == "guide" })?.value {
                appURL = .windowURL(url: .guide(id: id), universal: false)
            }
        } else if url.scheme == "celestia" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                if components.host == "article" {
                    if let id = components.path.split(separator: "/").filter({ !$0.isEmpty }).first {
                        appURL = .windowURL(url: .guide(id: String(id)), universal: false)
                    }
                } else if components.host == "addon" {
                    if let id = components.path.split(separator: "/").filter({ !$0.isEmpty }).first {
                        appURL = .windowURL(url: .addon(id: String(id)), universal: false)
                    }
                } else if components.host == "object" {
                    let path = components.path.split(separator: "/").filter({ !$0.isEmpty }).joined(separator: "/")
                    if !path.isEmpty {
                        let action: ObjectURLAction?
                        if let value = components.queryItems?.first(where: { $0.name == "action" })?.value {
                            action = ObjectURLAction(rawValue: value)
                        } else {
                            action = nil
                        }
                        appURL = .windowURL(url: .object(path: path, action: action), universal: false)
                    }
                }
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                if components.path == "/resources/item" {
                    // Handle shared add-on
                    if let id = components.queryItems?.first(where: { $0.name == "item" })?.value {
                        appURL = .windowURL(url: .addon(id: id), universal: true)
                    }
                } else if components.path == "/resources/guide" {
                    // Handle shared add-on
                    if let id = components.queryItems?.first(where: { $0.name == "guide" })?.value {
                        appURL = .windowURL(url: .guide(id: id), universal: true)
                    }
                }
            }
        }
        return appURL
    }

    public static func from(userActivity: NSUserActivity) -> AppURL? {
        guard let url = userActivity.webpageURL else { return nil }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        return from(url: url, openInPlace: false)
    }
}
