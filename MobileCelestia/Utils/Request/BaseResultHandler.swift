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
}

typealias RequestHandler = JSONRequestHandler<BaseResult>

extension RequestHandler {
    class func post<T: Decodable>(url: String,
                                  parameters: [String: String] = [:],
                                  success: ((T) -> Void)? = nil,
                                  failure: ((WrappedError) -> Void)? = nil,
                                  decoder: JSONDecoder = JSONDecoder(),
                                  session: URLSession = .shared) -> Self {
        return post(url: url, parameters: parameters, success: { (output) in
            guard output.status == 0 else {
                DispatchQueue.main.async { failure?(.serverError(message: output.info.reason)) }
                return
            }
            guard let dataString = output.info.detail else {
                DispatchQueue.main.async { failure?(.missingBody) }
                return
            }
            let data = Data(dataString.utf8)
            do {
                let result = try decoder.decode(T.self, from: data)
                DispatchQueue.main.async { success?(result) }
            } catch {
                DispatchQueue.main.async { failure?(.decodingError(error: error)) }
            }
        }, failure: { error in
            DispatchQueue.main.async { failure?(.requestError(error: error)) }
        }, session: session)
    }

    class func get<T: Decodable>(url: String,
                                 parameters: [String: String] = [:],
                                 success: ((T) -> Void)? = nil,
                                 failure: ((WrappedError) -> Void)? = nil,
                                 decoder: JSONDecoder = JSONDecoder(),
                                 queue: DispatchQueue = .main,
                                 session: URLSession = .shared) -> Self {
        return get(url: url, parameters: parameters, success: { (output) in
            guard output.status == 0 else {
                DispatchQueue.main.async { failure?(.serverError(message: output.info.reason)) }
                return
            }
            guard let dataString = output.info.detail else {
                DispatchQueue.main.async { failure?(.missingBody) }
                return
            }
            let data = Data(dataString.utf8)
            do {
                let result = try decoder.decode(T.self, from: data)
                DispatchQueue.main.async { success?(result) }
            } catch {
                DispatchQueue.main.async { failure?(.decodingError(error: error)) }
            }
        }, failure: { error in
            DispatchQueue.main.async { failure?(.requestError(error: error)) }
        }, session: session)
    }
}
