// QuickAction.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation
import UIKit

public enum QuickAction: Int, CaseIterable {
    case mode
    case info
    case search
    case menu
    case hide
    case zoomIn
    case zoomOut
    case go

    init?(id: String) {
        switch id {
        case "mode":
            self = .mode
        case "info":
            self = .info
        case "search":
            self = .search
        case "menu":
            self = .menu
        case "hide":
            self = .hide
        case "zoom_in":
            self = .zoomIn
        case "zoom_out":
            self = .zoomOut
        case "go":
            self = .go
        default:
            return nil
        }
    }

    var id: String {
        switch self {
        case .mode:
            "mode"
        case .info:
            "info"
        case .search:
            "search"
        case .menu:
            "menu"
        case .hide:
            "hide"
        case .zoomIn:
            "zoom_in"
        case .zoomOut:
            "zoom_out"
        case .go:
            "go"
        }
    }
}

@available(iOS 15, *)
public extension QuickAction {
    var title: String {
        switch self {
        case .mode:
            return CelestiaString("Toggle Interaction Mode", comment: "Touch interaction mode")
        case .info:
            return CelestiaString("Get Info", comment: "Action for getting info about current selected object")
        case .search:
            return CelestiaString("Search", comment: "")
        case .menu:
            return CelestiaString("Menu", comment: "Menu button")
        case .hide:
            return CelestiaString("Hide", comment: "Action to hide the tool overlay")
        case .zoomIn:
            return CelestiaString("Zoom In", comment: "")
        case .zoomOut:
            return CelestiaString("Zoom Out", comment: "")
        case .go:
            return CelestiaString("Go", comment: "Go to an object")
        }
    }

    @MainActor
    func image(with assetProvider: AssetProvider) -> UIImage? {
        switch self {
        case .mode:
            return UIImage(systemName: "cube")
        case .info:
            return UIImage(systemName: "info.circle")
        case .search:
            return UIImage(systemName: "magnifyingglass.circle")
        case .menu:
            return UIImage(systemName: "line.3.horizontal.circle")
        case .hide:
            return UIImage(systemName: "xmark.circle")
        case .zoomIn:
            return UIImage(systemName: "plus.circle")
        case .zoomOut:
            return UIImage(systemName: "minus.circle")
        case .go:
            return UIImage(systemName: "paperplane.circle")
        }
    }

    var deletable: Bool {
        switch self {
        case .menu:
            return false
        default:
            return true
        }
    }
}

public extension QuickAction {
    static var defaultItems: [QuickAction] {[
        .mode,
        .info,
        .search,
        .menu,
        .hide
    ]}

    static func from(_ string: String) -> [QuickAction]? {
        var results = [QuickAction]()
        for component in string.components(separatedBy: ",") {
            guard let action = QuickAction(id: component) else {
                return nil
            }
            if !results.contains(action) {
                results.append(action)
            }
        }
        return results
    }

    static func toString(_ actions: [QuickAction]) -> String {
        return actions.map { $0.id }.joined(separator: ",")
    }
}
