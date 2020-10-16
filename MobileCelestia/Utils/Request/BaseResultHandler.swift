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

struct BaseResult: JSONDecodable {
    static var decoder: JSONDecoder? { return nil }

    struct Info: Decodable {
        let detail: String?
        let reason: String?
    }

    let status: Int
    let info: Info
}

typealias RequestHandler = JSONRequestHandler<BaseResult>

extension RequestHandler {
    class func post<T: Decodable>(url: String,
                                  params: [String:String] = [:],
                                  success: ((T) -> Void)? = nil,
                                  fail: FailHandler? = nil,
                                  decoder: JSONDecoder = JSONDecoder(),
                                  queue: DispatchQueue = .main,
                                  session: URLSession = .shared) -> Self {
        return post(url: url, params: params, success: { (output) in
            func unexpectedServerError() { fail?(CelestiaString("Unknown error", comment: "")) }
            guard output.status == 0, let data = output.info.detail?.data(using: .utf8) else {
                unexpectedServerError()
                return
            }
            do {
                let result = try decoder.decode(T.self, from: data)
                success?(result)
            } catch {
                unexpectedServerError()
            }
        }, fail: fail, queue: queue, session: session)
    }

    class func get<T: Decodable>(url: String,
                                  params: [String:String] = [:],
                                  success: ((T) -> Void)? = nil,
                                  fail: FailHandler? = nil,
                                  decoder: JSONDecoder = JSONDecoder(),
                                  queue: DispatchQueue = .main,
                                  session: URLSession = .shared) -> Self {
        return get(url: url, params: params, success: { (output) in
            func unexpectedServerError() { fail?(CelestiaString("Unknown error", comment: "")) }
            guard output.status == 0, let data = output.info.detail?.data(using: .utf8) else {
                unexpectedServerError()
                return
            }
            do {
                let result = try decoder.decode(T.self, from: data)
                success?(result)
            } catch {
                unexpectedServerError()
            }
        }, fail: fail, queue: queue, session: session)
    }
}
