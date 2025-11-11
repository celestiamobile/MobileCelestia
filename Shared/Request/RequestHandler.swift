// RequestHandler.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation
import CelestiaUI
import MWRequest

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

final class RequestHandlerImpl: RequestHandler {
    public func getSubscriptionValidity(originalTransactionID: UInt64, sandbox: Bool) async throws -> Bool {
        struct ValidationResult: JSONDecodable {
            public static let decoder: JSONDecoder? = nil

            let valid: Bool
        }

        let result: ValidationResult = try await AsyncJSONRequestHandler.get(url: "https://celestia.mobi/api/subscription/apple", parameters: [
            "originalTransactionId": "\(originalTransactionID)",
            "sandbox": sandbox ? "1" : "0",
            "errorAsHttpStatus": "true",
        ])
        return result.valid
    }

    public func getMetadata(id: String, language: String) async throws -> ResourceItem {
        return try await AsyncJSONRequestHandler.get(url: URL.addonMetadata.absoluteString, parameters: ["lang": language, "item": id, "errorAsHttpStatus": "true"])
    }

    func getLatestMetadata(language: String) async throws -> GuideItem {
        return try await AsyncJSONRequestHandler.get(url: URL.latestGuideMetadata.absoluteString, parameters: ["lang": language, "type": "news", "errorAsHttpStatus": "true"])
    }
}
