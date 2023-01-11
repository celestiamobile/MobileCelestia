//
// BaseResultHandler.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation
import MWRequest

struct BaseResult: JSONDecodable {
    static var decoder: JSONDecoder? { return nil }

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

typealias RequestHandler = AsyncJSONRequestHandler<BaseResult>

extension RequestHandler {
    class func getDecoded<T: Decodable>(url: String,
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
