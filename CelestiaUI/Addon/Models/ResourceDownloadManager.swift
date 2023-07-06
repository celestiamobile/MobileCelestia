//
// ResourceDownloadManager.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

final class ResourceManager {
    static let downloadProgress = Notification.Name("ResourceDownloadManagerDownloadProgress")
    static let downloadSuccess = Notification.Name("ResourceDownloadManagerDownloadSuccess")
    static let downloadError = Notification.Name("ResourceDownloadManagerDownloadError")
    static let unzipSuccess = Notification.Name("ResourceDownloadManagerUnzipSuccess")

    static let downloadIdentifierKey = "ResourceDownloadManagerDownloadIdentifierKey"
    static let downloadProgressKey = "ResourceDownloadManagerDownloadProgressKey"
    static let downloadErrorKey = "ResourceDownloadManagerDownloadErrorKey"

    static let shared = ResourceManager()
    private var tasks: [String: URLSessionTask] = [:]

    private var observations: [String: NSKeyValueObservation] = [:]

    private init() {}

    func isDownloading(identifier: String) -> Bool {
        return tasks[identifier] != nil
    }

    func isInstalled(identifier: String) -> Bool {
        guard let addonDirectory = extraAddonDirectory else { return false }
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: addonDirectory.path + "/\(identifier)", isDirectory: &isDir) && isDir.boolValue
    }

    func download(url: URL, identifier: String) {
        let downloadTask = URLSession.shared.downloadTask(with: url) { [unowned self] url, response, error in
            self.tasks.removeValue(forKey: identifier)
            self.observations.removeValue(forKey: identifier)?.invalidate()

            if let e = error {
                // Download error
                NotificationCenter.default.post(name: Self.downloadError, object: nil, userInfo: [Self.downloadIdentifierKey: identifier, Self.downloadErrorKey: e])
            } else {
                // Download success
                NotificationCenter.default.post(name: Self.downloadSuccess, object: nil, userInfo: [Self.downloadIdentifierKey: identifier])
            }
        }
        let observation = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
            // Download progress
            NotificationCenter.default.post(name: Self.downloadProgress, object: nil, userInfo: [Self.downloadIdentifierKey: identifier, Self.downloadProgressKey: progress.fractionCompleted])
        }
        observations[identifier] = observation
        tasks[identifier] = downloadTask
        downloadTask.resume()
    }

    func cancel(identifier: String) {
        tasks.removeValue(forKey: identifier)?.cancel()
        observations.removeValue(forKey: identifier)?.invalidate()
    }
}
