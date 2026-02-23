//
// PerformActionIntent.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import AppIntents
import CelestiaCore
import CelestiaFoundation

@available(iOS 16.0, visionOS 1.0, *)
enum PerformActionEnum: String, AppEnum {
    case select
    case go
    case center
    case follow
    case chase
    case track
    case syncOrbit
    case lock
    case land

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Action")

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .select: "Select",
        .go: "Go",
        .center: "Center",
        .follow: "Follow",
        .chase: "Chase",
        .track: "Track",
        .syncOrbit: "Sync Orbit",
        .lock: "Lock",
        .land: "Land",
    ]

    var action: ObjectURLAction {
        switch self {
        case .select:
            .select
        case .center:
            .center
        case .go:
            .go
        case .follow:
            .follow
        case .chase:
            .chase
        case .track:
            .track
        case .syncOrbit:
            .syncOrbit
        case .lock:
            .lock
        case .land:
            .land
        }
    }
}

@available(iOS 16, visionOS 1, *)
struct PerformActionIntent: AppIntent {
    static let title: LocalizedStringResource = "Perform an action on an astronomical object"
    static let description = IntentDescription("Opens the app and performs an action on an astronomical object.")

    static let openAppWhenRun: Bool = true

    @Dependency
    var stateManager: StateManager

    @Parameter(
        title: "Object",
        description: "The name or the path of the celestial object to perform an action on.",
        requestValueDialog: IntentDialog("Which celestial body would you like to perform an action on?")
    )
    var object: String

    @Parameter(
        title: "Action",
        description: "The action to perform on the celestial object.",
        default: .select,
        requestValueDialog: IntentDialog("What action would you like to take?")
    )
    var action: PerformActionEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Perform \(\.$action) on \(\.$object)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let objectPath = object
        try await stateManager.waitForInitialization(.perform(objectPath: objectPath, action: action.action))
        return .result()
    }
}
