//
// SceneDelegate.swift
//
// Copyright © 2024 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaFoundation
import SwiftUI
import UIKit

@Observable class URLManager {
    var savedURL: AppURL?
}

enum WindowURL: Codable, Hashable {
    case addon(id: String)
    case guide(id: String)
}

enum AppURL: Codable, Hashable {
    case celScript(url: URL)
    case celURL(url: URL)
    case windowURL(url: WindowURL, universal: Bool)
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        var appURL: AppURL?
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

        guard let appURL else { return }
        AppDelegate.sharedDelegate?.urlManager?.savedURL = appURL
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        let url = urlContext.url
        var appURL: AppURL?
        if url.isFileURL {
            if urlContext.options.openInPlace {
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
        }

        guard let appURL else { return }
        AppDelegate.sharedDelegate?.urlManager?.savedURL = appURL
    }
}
