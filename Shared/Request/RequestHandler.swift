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

struct BaseResult: JSONDecodable {
    public static var decoder: JSONDecoder? { return nil }

    struct Info: Decodable {
        let detail: String?
        let reason: String?
    }

    let status: Int
    let info: Info
}

enum WrappedError: Error {
    case missingBody
    case requestError(error: RequestError)
    case serverError(message: String?)
    case decodingError(error: Error)
    case unknown
}

extension AsyncJSONRequestHandler<BaseResult> {
    static func getDecoded<T: Decodable>(url: String,
                                         parameters: [String: String] = [:],
                                         decoder: JSONDecoder = JSONDecoder(),
                                         session: URLSession = .shared) async throws -> T {
        do {
            let output = try await get(url: url, parameters: parameters, session: session)
            guard output.status == 0 else {
                throw WrappedError.serverError(message: output.info.reason)
            }
            guard let dataString = output.info.detail else {
                throw WrappedError.missingBody
            }
            let data = Data(dataString.utf8)
            do {
                let result = try decoder.decode(T.self, from: data)
                return result
            } catch {
                throw WrappedError.decodingError(error: error)
            }
        } catch {
            if let e = error as? RequestError {
                throw WrappedError.requestError(error: e)
            } else if let e = error as? WrappedError {
                throw e
            } else {
                throw WrappedError.unknown
            }
        }
    }
}

final class RequestHandlerImpl: RequestHandler {
    public func getSubscriptionValidity(originalTransactionID: UInt64, sandbox: Bool) async throws -> Bool {
        struct ValidationResult: Decodable {
            let valid: Bool
        }

        let result: ValidationResult = try await AsyncJSONRequestHandler.getDecoded(url: "https://celestia.mobi/api/subscription/apple", parameters: [
            "originalTransactionId": "\(originalTransactionID)",
            "sandbox": sandbox ? "1" : "0"
        ])
        return result.valid
    }

    public func getMetadata(id: String, language: String) async throws -> ResourceItem {
        return try await AsyncJSONRequestHandler.getDecoded(url: URL.addonMetadata.absoluteString, parameters: ["lang": language, "item": id], decoder: ResourceItem.networkResponseDecoder)
    }

    func getLatestMetadata(language: String) async throws -> GuideItem {
        return try await AsyncJSONRequestHandler.getDecoded(url: URL.latestGuideMetadata.absoluteString, parameters: ["lang": language, "type": "news"])
    }
}
