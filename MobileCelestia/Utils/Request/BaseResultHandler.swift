//
//  BaseResultHandler.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/29.
//  Copyright © 2020 李林峰. All rights reserved.
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
            func unexpectedServerError() { fail?(NSLocalizedString("Unknown error", comment: "")) }
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
