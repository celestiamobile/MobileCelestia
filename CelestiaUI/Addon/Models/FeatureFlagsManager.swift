// FeatureFlagsManager.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation

public final class FeatureFlagsManager: @unchecked Sendable {
    // Add new flag keys here
    private static let flagKeys = ["dummy"]

    private static let storageKey = "FeatureFlagsData"
    private static let deviceIDKey = "FeatureFlagsDeviceID"

    private let requestHandler: RequestHandler
    private let userDefaults: UserDefaults
    private let platform: String
    private let bundle: Bundle

    public init(requestHandler: RequestHandler, userDefaults: UserDefaults, platform: String, bundle: Bundle) {
        self.requestHandler = requestHandler
        self.userDefaults = userDefaults
        self.platform = platform
        self.bundle = bundle
    }

    public func update(language: String) async {
        do {
            let result = try await requestHandler.getFeatureFlags(platform: platform, language: language, version: bundle.shortVersion)

            let deviceId: String
            if let stored = userDefaults.string(forKey: Self.deviceIDKey) {
                deviceId = stored
            } else {
                let newId = UUID().uuidString
                userDefaults.set(newId, forKey: Self.deviceIDKey)
                deviceId = newId
            }

            var evaluated = [String: Bool]()
            for key in Self.flagKeys {
                guard let progress = result[key] else { continue }
                let combined = deviceId + key
                let seed = Double(stableHash(combined)) / Double(UInt64.max)
                evaluated[key] = seed < progress
            }

            var json = [String: Any]()
            for key in Self.flagKeys {
                json[key] = evaluated[key] ?? false
            }
            if let data = try? JSONSerialization.data(withJSONObject: json),
               let jsonString = String(data: data, encoding: .utf8) {
                userDefaults.set(jsonString, forKey: Self.storageKey)
            }
        } catch {}
    }

    public func get() -> FeatureFlags {
        guard let jsonString = userDefaults.string(forKey: Self.storageKey),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return FeatureFlags()
        }
        return FeatureFlags(
            dummy: json["dummy"] as? Bool ?? false
        )
    }

    private func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 5381
        for byte in string.utf8 {
            hash = (hash &* 33) &+ UInt64(byte)
        }
        return hash
    }
}
