//
// AddonUpdateManager.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Combine
import Foundation

@MainActor
public class AddonUpdateManager {
    struct PendingAddonUpdate: Hashable, Sendable {
        let update: AddonUpdate
        let addon: ResourceItem
    }

    enum CheckReason {
        case change
        case refresh
        case viewAppear
    }

    private var addonUpdates = [String: AddonUpdate]()
    private var didCheckOnViewAppear = false

    @Published var isCheckingUpdates: Bool = false
    var pendingUpdates: [PendingAddonUpdate] = []

    private let requestHandler: RequestHandler
    private let resourceManager: ResourceManager

    public init(requestHandler: RequestHandler, resourceManager: ResourceManager) {
        self.requestHandler = requestHandler
        self.resourceManager = resourceManager
    }

    func refresh(reason: CheckReason, originalTransactionID: UInt64, sandbox: Bool, language: String) async -> Bool {
        let installedAddons = resourceManager.installedResources()
        var success = true

        let needCheckUpdates: Bool
        switch reason {
        case .change:
            needCheckUpdates = false
        case .refresh:
            needCheckUpdates = true
        case .viewAppear:
            needCheckUpdates = !didCheckOnViewAppear
            didCheckOnViewAppear = true
        }

        if needCheckUpdates && !isCheckingUpdates {
            isCheckingUpdates = true
            let installedAddonIds = installedAddons.compactMap { $0.checksum != nil ? $0.id : nil }
            do {
                let result = try await requestHandler.getUpdates(addonIds: installedAddonIds, language: language, originalTransactionID: originalTransactionID, sandbox: sandbox)
                addonUpdates = result
            } catch {
                success = false
            }
            isCheckingUpdates = false
        }

        var updates = [PendingAddonUpdate]()
        for addon in installedAddons {
            if let update = addonUpdates[addon.id], addon.checksum != nil, addon.checksum != update.checksum {
                updates.append(PendingAddonUpdate(update: update, addon: addon))
            }
        }
        pendingUpdates = updates

        return success
    }
}
