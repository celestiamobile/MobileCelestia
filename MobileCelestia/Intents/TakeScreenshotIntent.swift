//
// TakeScreenshotIntent.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import AppIntents
import CelestiaFoundation
import Foundation
import UniformTypeIdentifiers

@available(iOS 16, visionOS 1, *)
struct TakeScreenshotIntent: AppIntent {
    static let title: LocalizedStringResource = "Take a screenshot"
    static let description = IntentDescription("Opens the app, captures a screenshot, and returns it as a file.")

    static let openAppWhenRun: Bool = true

    @Dependency
    var stateManager: StateManager

    static var parameterSummary: some ParameterSummary {
        Summary("Take a screenshot")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let outputURL = try URL.temp().appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        try await stateManager.waitForInitialization(.celestia(.screenshot(outputURL: outputURL)))
        let data = try Data(contentsOf: outputURL)
        try? FileManager.default.removeItem(at: outputURL)
        let file = IntentFile(data: data, filename: "CelestiaScreenshot.png", type: .png)
        return .result(value: file)
    }
}
