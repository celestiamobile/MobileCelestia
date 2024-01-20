//
//  AsyncRequestHandler.swift
//  
//
//  Created by Levin Li on 2022/1/31.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if compiler(>=5.5) && canImport(_Concurrency)
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, visionOS 1.0, *)
open class AsyncBaseRequestHandler<Output> {
    private class func commonHandler(data: Data, response: URLResponse) async throws -> Output {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw RequestError.noResponse
        }
        guard statusCode < 400 else {
            throw RequestError.httpError(statusCode: statusCode, errorString: HTTPURLResponse.localizedString(forStatusCode: statusCode), responseBody: data)
        }
        return try await handleData(data)
    }

    open class func handleData(_ data: Data) async throws -> Output {
        fatalError("Subclass should implement handleData:")
    }

    public class func get(url: String,
                          parameters: [String: String] = [:],
                          headers: [String: String]? = nil,
                          session: URLSession = .shared) async throws -> Output {
        var dataResponseTuple: (data: Data, response: URLResponse)!
        do {
            dataResponseTuple = try await session.get(from: url, parameters: parameters, headers: headers)
        }
        catch {
            throw RequestError.urlSessionError(error: error)
        }
        return try await commonHandler(data: dataResponseTuple.data, response: dataResponseTuple.response)
    }

    public class func post(url: String,
                           parameters: [String: String] = [:],
                           headers: [String: String]? = nil,
                           session: URLSession = .shared) async throws -> Output {
        var dataResponseTuple: (data: Data, response: URLResponse)!
        do {
            dataResponseTuple = try await session.post(to: url, parameters: parameters, headers: headers)
        }
        catch {
            throw RequestError.urlSessionError(error: error)
        }
        return try await commonHandler(data: dataResponseTuple.data, response: dataResponseTuple.response)
    }

    public class func post<T: Encodable>(url: String,
                                         json: T,
                                         encoder: JSONEncoder? = nil,
                                         headers: [String: String]? = nil,
                                         session: URLSession = .shared) async throws -> Output {
        var dataResponseTuple: (data: Data, response: URLResponse)!
        do {
            dataResponseTuple = try await session.post(to: url, json: json, encoder: encoder, headers: headers)
        }
        catch {
            throw RequestError.urlSessionError(error: error)
        }
        return try await commonHandler(data: dataResponseTuple.data, response: dataResponseTuple.response)
    }

    public class func upload(url: String,
                             data: Data, key: String = "file", filename: String,
                             parameters: [String: String] = [:],
                             headers: [String: String]? = nil,
                             session: URLSession = .shared) async throws -> Output {
        var dataResponseTuple: (data: Data, response: URLResponse)!
        do {
            dataResponseTuple = try await session.upload(to: url, parameters: parameters, data: data, key: key, filename: filename, headers: headers)
        }
        catch {
            throw RequestError.urlSessionError(error: error)
        }
        return try await commonHandler(data: dataResponseTuple.data, response: dataResponseTuple.response)
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, visionOS 1.0, *)
public class AsyncEmptyRequestHandler: AsyncBaseRequestHandler<Void> {
    public override class func handleData(_ data: Data) async throws -> Void {
        return ()
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, visionOS 1.0, *)
public class AsyncDataRequestHandler: AsyncBaseRequestHandler<Data> {
    public override class func handleData(_ data: Data) async throws -> Data {
        return data
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, visionOS 1.0, *)
public class AsyncJSONRequestHandler<Output>: AsyncBaseRequestHandler<Output> where Output: JSONDecodable {

    public override class func handleData(_ data: Data) async throws -> Output {
        do {
            return try (Output.decoder ?? JSONDecoder()).decode(Output.self, from: data)
        } catch {
            throw RequestError.decodingError(error: error)
        }
    }
}
#endif
