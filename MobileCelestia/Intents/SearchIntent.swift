//
// SearchIntent.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import AppIntents

@available(iOS 18, macOS 15, visionOS 2, *)
@AppIntent(schema: .system.search)
struct SearchIntent: ShowInAppSearchResultsIntent {
    static let searchScopes: [StringSearchScope] = [.general]

    var criteria: StringSearchCriteria

    @Dependency
    var stateManager: StateManager

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        try await stateManager.waitForInitialization(.search(term: criteria.term))
        return .result()
    }
}
