//
// Request.swift
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

public extension URLSession {
    func post(to url: String, parameters: [String : String], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.setPostParameters(parameters)
        let task = dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        return task
    }

    func upload(to url: String, parameters: [String: String], data: Data, filename: String,  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.setUploadParameters(parameters, data: data, filename: filename)
        let task = dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        return task
    }

    func get(from url: String, parameters: [String: String], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let suffix = parameters.urlQueryEncoded
        let url = URL(string: (suffix.count > 0 ? "\(url)?\(suffix)" : url))
        let task = dataTask(with: url!, completionHandler: completionHandler)
        task.resume()
        return task
    }
}

fileprivate extension Data {
    mutating func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}

fileprivate extension Dictionary where Key == String, Value == String {
    var urlQueryEncoded: String {
        return self.map {"\($0)=\($1)"}.joined(separator: "&").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
}

fileprivate extension URLRequest {
    mutating func setPostParameters(_ parameters: [String : String]) {
        httpMethod = "POST"
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        httpBody = parameters.urlQueryEncoded.data(using: String.Encoding.utf8)
    }

    mutating func setUploadParameters(_ parameters: [String : String], data: Data, filename: String) {
        let boundary = "Boundary-\(UUID().uuidString)"
        let mimeType = "application/octet-stream"

        /* Create upload body */
        var body = Data()
        /* Key/value pairs */
        let boundaryPrefix = "--\(boundary)\r\n"
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        /* File information */
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        /* File data */
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))

        httpMethod = "POST"
        httpBody = body
        setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        httpBody = parameters.urlQueryEncoded.data(using: String.Encoding.utf8)
    }
}

fileprivate extension CharacterSet {
    static var allowedURLCharacterSet: CharacterSet {
        return .urlQueryAllowed
    }
}
