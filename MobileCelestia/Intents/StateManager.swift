//
// StateManager.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import CelestiaFoundation
import CelestiaUI
import Foundation

enum CelestiaRequest {
    case goTo(objectPath: String, latitude: Float, longitude: Float, distance: Double, distanceUnit: DistanceUnit, travelDuration: Double)
    case perform(objectPath: String, action: ObjectURLAction)
    case runScript(scriptURL: URL)
}

enum AppRequest {
    case celestia(CelestiaRequest)
    case search(term: String)
}

enum AppRequestError: Error {
    case failedToLoad
    case objectNotFound(objectPath: String)
    case invalidScript
}

@available(iOS 16, visionOS 1, *)
extension AppRequestError: CustomLocalizedStringResourceConvertible {
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .failedToLoad: return "Celestia failed to initialize."
        case let .objectNotFound(objectPath): return "Unable to find object \(objectPath)."
        case .invalidScript: return "The script is invalid or empty."
        }
    }
}

@MainActor
class StateManager {
    enum State {
        case failedToLoad
        case loaded(AppCore)
    }

    static let shared: StateManager = StateManager()

    private var core: AppCore?
    private(set) var state: State? = nil {
        didSet {
            if let state {
                Task {
                    await resumePendingContinuations(state: state)
                }
            }
        }
    }

    private var continuations: [(continuation: CheckedContinuation<Void, Error>, request: AppRequest)] = []

    var hasPendingRequests: Bool { !continuations.isEmpty }

    var hasPendingCelestiaRequests: Bool {
        for continuation in continuations {
            switch continuation.request {
            case .celestia:
                return true
            case .search:
                break
            }
        }
        return false
    }

    func waitForInitialization(_ request: AppRequest) async throws {
        // 1. If already initialized, return immediately
        if let state {
            switch state {
            case .failedToLoad:
                throw AppRequestError.failedToLoad
            case let .loaded(appCore):
                try await executeRequest(request, appCore: appCore)
            }
            return
        }

        // 2. Suspend and wait
        return try await withCheckedThrowingContinuation { continuation in
            continuations.append((continuation, request))
        }
    }

    func markAsInitialized(_ state: State) {
        self.state = state
    }

    private func resumePendingContinuations(state: State) async {
        for (continuation, request) in continuations {
            switch state {
            case .failedToLoad:
                continuation.resume(throwing: AppRequestError.failedToLoad)
            case let .loaded(appCore):
                do {
                    try await executeRequest(request, appCore: appCore)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        continuations.removeAll()
    }

    private func executeRequest(_ request: AppRequest, appCore: AppCore) async throws {
        switch request {
        case .search(let term):
            NotificationCenter.default.post(name: requestSearchNotificationName, object: nil, userInfo: [requestSearchNotificationTermKey: term])
        case .celestia(let celestiaRequest):
            try await executeCelestiaRequest(celestiaRequest, appCore: appCore)
        }
    }

    private func executeCelestiaRequest(_ request: CelestiaRequest, appCore: AppCore) async throws {
        try await Task { @CelestiaActor in
            switch request {
            case let .goTo(objectPath, latitude, longitude, distance, distanceUnit, travelDuration):
                let selection = appCore.simulation.findObject(from: objectPath)
                if selection.isEmpty {
                    throw AppRequestError.objectNotFound(objectPath: objectPath)
                } else {
                    let location = GoToLocation(selection: selection, longitude: longitude, latitude: latitude, distance: distance, unit: distanceUnit)
                    appCore.tick()
                    location.duration = travelDuration
                    appCore.simulation.go(to: location)
                }
            case let .perform(objectPath, action: action):
                let selection = appCore.simulation.findObject(from: objectPath)
                if selection.isEmpty {
                    throw AppRequestError.objectNotFound(objectPath: objectPath)
                } else {
                    appCore.tick()
                    let objectAction = ObjectAction(action)
                    switch objectAction {
                    case .select:
                        appCore.simulation.selection = selection
                    case let .wrapped(action):
                        appCore.simulation.selection = selection
                        appCore.receive(action)
                    default:
                        break
                    }
                }
            case let .runScript(scriptURL):
                appCore.runScript(at: scriptURL.path)
            }
        }.value
    }
}
