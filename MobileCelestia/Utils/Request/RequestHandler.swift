//
// RequestHandler.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public class BaseRequestHandler<Output> {
    public typealias SuccessHandler = (Output) -> Void
    public typealias FailHandler = (String) -> Void
    fileprivate let successHandler: SuccessHandler?
    fileprivate let failHandler: FailHandler?
    fileprivate let resultQueue: DispatchQueue
    fileprivate var dataTask: URLSessionDataTask?

    required init(success: SuccessHandler?, fail: FailHandler?, queue: DispatchQueue) {
        failHandler = fail
        successHandler = success
        resultQueue = queue
    }

    public func cancel() {
        dataTask?.cancel()
    }

    fileprivate func asyncFailHandler(message: String) {
        guard let fail = failHandler else { return }
        resultQueue.async { fail(message) }
    }

    fileprivate func asyncSuccessHandler(output: Output) {
        guard let success = successHandler else { return }
        resultQueue.async { success(output) }
    }

    fileprivate func commonHandler(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        guard error == nil else {
            asyncFailHandler(message: error!.localizedDescription)
            return true
        }
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            asyncFailHandler(message: CelestiaString("No response", comment: ""))
            return true
        }
        guard statusCode < 400 else {
            asyncFailHandler(message: HTTPURLResponse.localizedString(forStatusCode:
                statusCode))
            return true
        }
        guard data != nil else {
            asyncFailHandler(message: CelestiaString("No data", comment: ""))
            return true
        }
        return false
    }

    public class func get(url: String,
                          params: [String:String] = [:],
                          success: SuccessHandler? = nil,
                          fail: FailHandler? = nil,
                          queue: DispatchQueue = .main,
                          session: URLSession = .shared) -> Self {
        let handler = self.init(success: success, fail: fail, queue: queue)
        let task = session.get(from: url, parameters: params) { (data, response, error) in
            _ = handler.commonHandler(data: data, response: response, error: error)
        }
        handler.dataTask = task
        return handler
    }

    public class func post(url: String,
                           params: [String:String] = [:],
                           success: SuccessHandler? = nil,
                           fail: FailHandler? = nil,
                           queue: DispatchQueue = .main,
                           session: URLSession = .shared) -> Self {
        let handler = self.init(success: success, fail: fail, queue: queue)
        let task = session.post(to: url, parameters: params) { (data, response, error) in
            _ = handler.commonHandler(data: data, response: response, error: error)
        }
        handler.dataTask = task
        return handler
    }

    public class func upload(url: String,
                             data: Data, filename: String,
                             params: [String:String] = [:],
                             success: SuccessHandler? = nil,
                             fail: FailHandler? = nil,
                             queue: DispatchQueue = .main,
                             session: URLSession = .shared) -> Self {
        let handler = self.init(success: success, fail: fail, queue: queue)
        let task = session.upload(to: url, parameters: params, data: data, filename: filename) { (data, response, error) in
            _ = handler.commonHandler(data: data, response: response, error: error)
        }
        handler.dataTask = task
        return handler
    }
}

public class EmptyRequestHandler: BaseRequestHandler<Void> {
    override func commonHandler(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        guard !super.commonHandler(data: data, response: response, error: error) else {
            return true
        }
        asyncSuccessHandler(output: ())
        return false
    }
}

public class DataRequestHandler: BaseRequestHandler<Data> {
    override func commonHandler(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        guard !super.commonHandler(data: data, response: response, error: error) else {
            return true
        }
        asyncSuccessHandler(output: data!)
        return false
    }
}

public protocol JSONDecodable: Decodable {
    static var decoder: JSONDecoder? { get }
}

extension Array: JSONDecodable where Element: JSONDecodable {
    public static var decoder: JSONDecoder? { return Element.decoder }
}

public class JSONRequestHandler<Output>: BaseRequestHandler<Output> where Output: JSONDecodable {
    override func commonHandler(data: Data?, response: URLResponse?, error: Error?) -> Bool {
        guard !super.commonHandler(data: data, response: response, error: error) else {
            return true
        }
        do {
            let output = try (Output.decoder ?? JSONDecoder()).decode(Output.self, from: data!)
            asyncSuccessHandler(output: output)
            return false
        } catch let error {
            asyncFailHandler(message: error.localizedDescription)
            return true
        }
    }
}
