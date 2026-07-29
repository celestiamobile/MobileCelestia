//
// RunScriptIntent.swift
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

@available(iOS 16.0, visionOS 1.0, *)
enum ScriptTypeEnum: String, AppEnum {
    case cel
    case celx

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Script Type")

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .cel: "CEL (.cel)",
        .celx: "Lua (.celx)"
    ]

    var fileExtension: String {
        return rawValue
    }
}

@available(iOS 16.0, visionOS 1.0, *)
enum ScriptSourceEnum: String, AppEnum {
    case text
    case file

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Script Source")

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .text: "Text",
        .file: "File"
    ]
}

@available(iOS 18, visionOS 2, *)
struct RunScriptIntent: AppIntent {
    static let title: LocalizedStringResource = "Run a script"
    static let description = IntentDescription("Opens the app and runs a Celestia script from text or a file.")

    static let openAppWhenRun: Bool = true

    @Dependency
    var stateManager: StateManager

    @Parameter(
        title: "Source",
        description: "Whether to run a script from text or from a file.",
        default: .file,
        requestValueDialog: IntentDialog("Would you like to run a script from text or from a file?")
    )
    var source: ScriptSourceEnum

    @Parameter(
        title: "Script Content",
        description: "The content of the script to run.",
        inputOptions: String.IntentInputOptions(multiline: true),
        requestValueDialog: IntentDialog("What script would you like to run?")
    )
    var scriptContent: String?

    @Parameter(
        title: "Script Type",
        description: "The type of the script.",
        default: .cel,
        requestValueDialog: IntentDialog("What type of script is this?")
    )
    var scriptType: ScriptTypeEnum

    @Parameter(
        title: "File",
        description: "The script file to run.",
        supportedContentTypes: [.data],
        requestValueDialog: IntentDialog("Which script file would you like to run?")
    )
    var file: IntentFile?

    static var parameterSummary: some ParameterSummary {
        Switch(\.$source) {
            Case(.file) {
                Summary("Run script from \(\.$file)") {
                    \.$source
                }
            }
            DefaultCase {
                Summary("Run \(\.$scriptType) script \(\.$scriptContent)") {
                    \.$source
                }
            }
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let scriptURL: URL
        switch source {
        case .text:
            let content: String
            if let scriptContent, !scriptContent.isEmpty {
                content = scriptContent
            } else {
                content = try await $scriptContent.requestValue(IntentDialog("What script would you like to run?"))
            }
            guard !content.isEmpty, let data = content.data(using: .utf8) else {
                throw AppRequestError.invalidScript
            }
            scriptURL = try Self.temporaryScriptURL(fileExtension: scriptType.fileExtension)
            try data.write(to: scriptURL, options: .atomic)
        case .file:
            let scriptFile: IntentFile
            if let file {
                scriptFile = file
            } else {
                scriptFile = try await $file.requestValue(IntentDialog("Which script file would you like to run?"))
            }
            let fileExtension = URL(fileURLWithPath: scriptFile.filename).pathExtension
            let resolvedExtension = ["cel", "celx"].contains(fileExtension.lowercased()) ? fileExtension : "cel"
            let data = scriptFile.data
            guard !data.isEmpty else {
                throw AppRequestError.invalidScript
            }
            scriptURL = try Self.temporaryScriptURL(fileExtension: resolvedExtension)
            try data.write(to: scriptURL, options: .atomic)
        }

        try await stateManager.waitForInitialization(.celestia(.runScript(scriptURL: scriptURL)))
        return .result()
    }

    private static func temporaryScriptURL(fileExtension: String) throws -> URL {
        let directory = try URL.temp()
        return directory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)
    }
}
