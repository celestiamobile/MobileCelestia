// RequestHandler.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import AsyncRequest
import Foundation
import CelestiaUI

extension GuideItem: @retroactive JSONDecodable {
    public static let decoder: JSONDecoder? = nil
}

extension ResourceItem: @retroactive JSONDecodable {
    public static let decoder: JSONDecoder? = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
}

extension AddonUpdate: @retroactive JSONDecodable {
    public static let decoder: JSONDecoder? = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
}

extension Dictionary: @retroactive JSONDecodable where Key == String, Value: Decodable {
    public static var decoder: JSONDecoder? {
        (Value.self as? any JSONDecodable.Type)?.decoder
    }
}

final class RequestHandlerImpl: RequestHandler {
    public func getSubscriptionValidity(originalTransactionID: UInt64, sandbox: Bool, productType: PurchaseType) async throws -> Bool {
        struct ValidationResult: JSONDecodable {
            public static let decoder: JSONDecoder? = nil

            let valid: Bool
        }

        let result: ValidationResult = try await AsyncJSONRequestHandler.get(url: URL.apiPrefixURL.appendingPathComponent("subscription/apple").absoluteString, parameters: [
            "originalTransactionId": "\(originalTransactionID)",
            "sandbox": sandbox ? "1" : "0",
            "productType": productType.rawValue,
        ], httpClient: URLSession.shared)
        return result.valid
    }

    public func getMetadata(id: String, language: String) async throws -> ResourceItem {
        return try await AsyncJSONRequestHandler.get(url: URL.addonMetadata.absoluteString, parameters: ["lang": language, "item": id], httpClient: URLSession.shared)
    }

    func getLatestMetadata(language: String) async throws -> GuideItem {
#if os(visionOS)
        let platform = "visionos"
#else
#if targetEnvironment(macCatalyst)
        let platform = "catalyst"
#else
        let platform = "ios"
#endif
#endif
        return try await AsyncJSONRequestHandler.get(url: URL.latestGuideMetadata.absoluteString, parameters: ["lang": language, "type": "news", "platform": platform], httpClient: URLSession.shared)
    }

    private struct UpdateRequest: Encodable {
        let lang: String
        let items: [String]
        let transactionIdApple: String
        let isSandboxApple: Bool
        let productType: PurchaseType
    }

    func getUpdates(addonIds: [String], language: String, originalTransactionID: UInt64, sandbox: Bool, productType: PurchaseType) async throws -> [String: AddonUpdate] {
        return try await AsyncJSONRequestHandler.post(url: URL.updates.absoluteString, json: UpdateRequest(lang: language, items: addonIds, transactionIdApple: "\(originalTransactionID)", isSandboxApple: sandbox, productType: productType), httpClient: URLSession.shared)
    }

    func getFeatureFlags(platform: String, language: String, version: String) async throws -> [String: Double] {
        return try await AsyncJSONRequestHandler.get(url: URL.features.absoluteString, parameters: ["platform": platform, "lang": language, "version": version], httpClient: URLSession.shared)
    }
}
