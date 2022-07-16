//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private extension URL {
    static func from(url: String, parameters: [String: String] = [:]) throws -> URL {
        if parameters.count == 0 {
            guard let newURL = URL(string: url) else {
                throw RequestError.urlError
            }
            return newURL
        }
        guard var components = URLComponents(string: url) else {
            throw RequestError.urlError
        }
        components.queryItems = parameters.count == 0 ? nil : parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let newURL = components.url else {
            throw RequestError.urlError
        }
        return newURL
    }
}

public extension URLSession {
    func post(to url: String, parameters: [String: String], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        do {
            let newURL = try URL.from(url: url)
            var request = URLRequest(url: newURL)
            try request.setPostParameters(parameters)
            let task = dataTask(with: request, completionHandler: completionHandler)
            task.resume()
            return task
        } catch {
            completionHandler(nil, nil, error)
            return nil
        }
    }

    func post<T: Encodable>(to url: String, json: T, encoder: JSONEncoder?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        do {
            let newURL = try URL.from(url: url)
            var request = URLRequest(url: newURL)
            try request.setPostParametersJson(json, encoder: encoder)
            let task = dataTask(with: request, completionHandler: completionHandler)
            task.resume()
            return task
        } catch {
            completionHandler(nil, nil, error)
            return nil
        }
    }

    func upload(to url: String, parameters: [String: String], data: Data, key: String, filename: String,  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? {
        do {
            let newURL = try URL.from(url: url)
            var request = URLRequest(url: newURL)
            try request.setUploadParameters(parameters, data: data, key: key, filename: filename)
            let task = dataTask(with: request, completionHandler: completionHandler)
            task.resume()
            return task
        } catch {
            completionHandler(nil, nil, error)
            return nil
        }
    }

    func get(from url: String, parameters: [String: String], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? {
        do {
            let newURL = try URL.from(url: url, parameters: parameters)
            let task = dataTask(with: newURL, completionHandler: completionHandler)
            task.resume()
            return task
        } catch {
            completionHandler(nil, nil, error)
            return nil
        }
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
private extension URLSession {
    func _dataCompat(for request: URLRequest) async throws -> (Data, URLResponse) {
        if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
            return try await data(for: request, delegate: nil)
        }
        return try await withCheckedThrowingContinuation { continuation in
            _ = dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (data!, response!))
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public extension URLSession {
    func post(to url: String, parameters: [String: String]) async throws -> (Data, URLResponse) {
        let newURL = try URL.from(url: url)
        var request = URLRequest(url: newURL)
        try request.setPostParameters(parameters)
        return try await _dataCompat(for: request)
    }

    func post<T: Encodable>(to url: String, json: T, encoder: JSONEncoder?) async throws -> (Data, URLResponse) {
        let newURL = try URL.from(url: url)
        var request = URLRequest(url: newURL)
        try request.setPostParametersJson(json, encoder: encoder)
        return try await _dataCompat(for: request)
    }

    func upload(to url: String, parameters: [String: String], data: Data, key: String, filename: String) async throws -> (Data, URLResponse) {
        let newURL = try URL.from(url: url)
        var request = URLRequest(url: newURL)
        try request.setUploadParameters(parameters, data: data, key: key, filename: filename)
        return try await _dataCompat(for: request)
    }

    func get(from url: String, parameters: [String: String]) async throws -> (Data, URLResponse) {
        let newURL = try URL.from(url: url, parameters: parameters)
        return try await _dataCompat(for: URLRequest(url: newURL))
    }
}

#if canImport(FoundationNetworking)
// swift-corelibs-foundation still has not integrated concurrency support for Linux yet...
extension URLSession {
    func data(for request: URLRequest, delegate: URLSessionDelegate?) async throws -> (data: Data, response: URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            dataTask(with: request, completionHandler: { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (data!, response!))
                }
            }).resume()
        }
    }
}
#endif
#endif

private extension URLRequest {
    mutating func setPostParametersJson<T: Encodable>(_ encodable: T, encoder: JSONEncoder?) throws {
        httpMethod = "POST"
        setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        do {
            httpBody = try (encoder ?? JSONEncoder()).encode(encodable)
        } catch {
            throw RequestError.urlError
        }
    }

    mutating func setPostParameters(_ parameters: [String: String]) throws {
        httpMethod = "POST"
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let query = try parameters.map({ (key, value) -> String in
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                throw RequestError.urlError
            }
            return "\(encodedKey)=\(encodedValue)"
        }).joined(separator: "&")
        if query.isEmpty {
            httpBody = nil
        } else {
            guard let data = query.data(using: .utf8) else {
                throw RequestError.urlError
            }
            httpBody = data
        }
    }

    mutating func setUploadParameters(_ parameters: [String: String], data: Data, key: String, filename: String) throws {
        let boundary = "Boundary-\(UUID().uuidString)"
        let mimeType = "application/octet-stream"

        /* Create upload body */
        var body = Data()

        func appendString(_ string: String) throws {
            guard let data = string.data(using: .utf8) else {
                throw RequestError.urlError
            }
            body.append(data)
        }

        /* Key/value pairs */
        let boundaryPrefix = "--\(boundary)\r\n"
        for (key, value) in parameters {
            try appendString(boundaryPrefix)
            try appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            try appendString("\(value)\r\n")
        }
        /* File information */
        try appendString(boundaryPrefix)
        try appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n")
        try appendString("Content-Type: \(mimeType)\r\n\r\n")
        /* File data */
        body.append(data)
        try appendString("\r\n")
        try appendString("--".appending(boundary.appending("--")))

        httpMethod = "POST"
        httpBody = body
        setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    }
}
