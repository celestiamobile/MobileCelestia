//
// OpenCelestiaURLIntent.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import AppIntents
import Foundation

@available(iOS 16, visionOS 1, *)
struct OpenCelestiaURLIntent: AppIntent {
    static let title: LocalizedStringResource = "Open a Celestia URL"
    static let description = IntentDescription("Opens the app and navigates to a cel:// URL.")

    static let openAppWhenRun: Bool = true

    @Dependency
    var stateManager: StateManager

    @Parameter(
        title: "URL",
        description: "The cel:// URL to open.",
        requestValueDialog: IntentDialog("Which Celestia URL would you like to open?")
    )
    var url: URL

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$url)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try await stateManager.waitForInitialization(.celestia(.openURL(url: url)))
        return .result()
    }
}
