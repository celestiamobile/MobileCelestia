//
// GoToIntent.swift
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

@available(iOS 16.0, visionOS 1.0, *)
enum DistanceUnitEnum: String, AppEnum {
    case km
    case radii
    case au

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Distance Unit")

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .km: "Kilometers",
        .radii: "Radii",
        .au: "Astronomical Units"
    ]

    var unit: DistanceUnit {
        switch self {
        case .km:
            return .KM
        case .radii:
            return .radii
        case .au:
            return .AU
        }
    }
}

@available(iOS 16, visionOS 1, *)
struct GoToIntent: AppIntent {
    static let title: LocalizedStringResource = "Go to an astronomical object"
    static let description = IntentDescription("Opens the app and goes to an astronomical object.")

    static let openAppWhenRun: Bool = true

    @Dependency
    var stateManager: StateManager

    @Parameter(
        title: "Object",
        description: "The name or the path of the celestial object to go to.",
        requestValueDialog: IntentDialog("Which celestial body would you like to visit?")
    )
    var object: String

    @Parameter(
        title: "Latitude",
        description: "Target latitude in degrees.",
        default: 0.0,
        inclusiveRange: (-90.0, 90.0),
        requestValueDialog: IntentDialog("What latitude would you like to view? (between -90 and 90 degrees)")
    )
    var latitude: Double

    @Parameter(
        title: "Longitude",
        description: "Target longitude in degrees.",
        default: 0.0,
        inclusiveRange: (-180.0, 180.0),
        requestValueDialog: IntentDialog("What longitude would you like to view? (between -180 and 180 degrees)")
    )
    var longitude: Double

    @Parameter(
        title: "Distance",
        description: "How far away from the object you want to view it from.",
        default: 8.0,
        inclusiveRange: (0.0, 1_000_000_000_000_000_000_000),
        requestValueDialog: IntentDialog("How far away from the object would you like to be?")
    )
    var distanceValue: Double

    @Parameter(
        title: "Distance Unit",
        description: "The unit for the distance.",
        default: .radii,
        requestValueDialog: IntentDialog("What unit would you like to use for distance?")
    )
    var distanceUnit: DistanceUnitEnum

    @Parameter(
        title: "Travel Duration",
        description: "Duration of the travel animation in seconds.",
        default: 5.0,
        inclusiveRange: (0.0, 1_000_000_000_000_000_000_000),
        requestValueDialog: IntentDialog("How long should the travel animation take in seconds?")
    )
    var travelDuration: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Go to \(\.$object)") {
            \.$latitude
            \.$longitude
            \.$distanceValue
            \.$distanceUnit
            \.$travelDuration
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let objectPath = object
        try await stateManager.waitForInitialization(.celestia(.goTo(objectPath: objectPath, latitude: Float(latitude), longitude: Float(longitude), distance: distanceValue, distanceUnit: distanceUnit.unit, travelDuration: travelDuration)))
        return .result()
    }
}
