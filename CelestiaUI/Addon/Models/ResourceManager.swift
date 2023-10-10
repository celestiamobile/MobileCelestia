//
// ResourceManager.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation
import ZIPFoundation

enum ResourceManagerError: Error {
    case addonDirectoryNotExists
}

extension ResourceManagerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .addonDirectoryNotExists:
            return CelestiaString("Add-on directory does not exist.", comment: "")
        }
    }
}

public final class ResourceManager: @unchecked Sendable {
    private let extraAddonDirectory: URL?

    // Notification names
    static let downloadProgress = Notification.Name("ResourceDownloadManagerDownloadProgress")
    static let downloadSuccess = Notification.Name("ResourceDownloadManagerDownloadSuccess")
    static let resourceError = Notification.Name("ResourceDownloadManagerResourceError")
    static let unzipSuccess = Notification.Name("ResourceDownloadManagerUnzipSuccess")

    // Notification user info keys
    static let downloadIdentifierKey = "ResourceDownloadManagerDownloadIdentifierKey"
    static let downloadProgressKey = "ResourceDownloadManagerDownloadProgressKey"
    static let resourceErrorKey = "ResourceDownloadManagerResourceErrorKey"

    private var tasks: [String: URLSessionTask] = [:]

    private var observations: [String: NSKeyValueObservation] = [:]

    public init(extraAddonDirectory: URL?) {
        self.extraAddonDirectory = extraAddonDirectory
    }

    func isDownloading(identifier: String) -> Bool {
        return tasks[identifier] != nil
    }

    func canInstallPlugins() -> Bool {
        guard let addonDirectory = extraAddonDirectory else { return false }
        let fm = FileManager.default
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: addonDirectory.path, isDirectory: &isDir) && isDir.boolValue
    }

    func isInstalled(identifier: String) -> Bool {
        guard let directory = contextDirectory(forAddonWithIdentifier: identifier) else { return false }
        return FileManager.default.fileExists(atPath: directory.path)
    }

    func contextDirectory(forAddonWithIdentifier identifier: String) -> URL? {
        guard let addonDirectory = extraAddonDirectory else { return nil }
        return addonDirectory.appendingPathComponent(identifier)
    }

    public func installedResources() -> [ResourceItem] {
        guard let addonDirectory = extraAddonDirectory else { return [] }
        var items = [ResourceItem]()
        let fm = FileManager.default
        guard let folders = try? fm.contentsOfDirectory(atPath: addonDirectory.path) else { return [] }
        for folder in folders {
            let descriptionFile = addonDirectory.appendingPathComponent(folder).appendingPathComponent("description.json")
            if let data = try? Data(contentsOf: descriptionFile),
               let content = try? JSONDecoder().decode(ResourceItem.self, from: data),
               content.id == folder {
                items.append(content)
            }
        }
        return items
    }

    func uninstall(identifier: String) throws {
        guard let addonDirectory = extraAddonDirectory else { return }
        try FileManager.default.removeItem(at: addonDirectory.appendingPathComponent(identifier))
    }

    func download(item: ResourceItem) {
        let downloadTask = URLSession.shared.downloadTask(with: item.item) { [unowned self] url, response, error in
            DispatchQueue.main.sync {
                self.tasks.removeValue(forKey: item.id)
                self.observations.removeValue(forKey: item.id)?.invalidate()
            }

            if let e = error {
                if (e as? URLError)?.errorCode == URLError.cancelled.rawValue {
                    // Canceled, do nothing
                } else {
                    // Download error
                    NotificationCenter.default.post(name: Self.resourceError, object: nil, userInfo: [Self.downloadIdentifierKey: item.id, Self.resourceErrorKey: e])
                }
            } else {
                // Download success
                NotificationCenter.default.post(name: Self.downloadSuccess, object: nil, userInfo: [Self.downloadIdentifierKey: item.id])
                do {
                    let destination = try unzip(identifier: item.id, zipFilePath: url!)
                    NotificationCenter.default.post(name: Self.unzipSuccess, object: nil, userInfo: [Self.downloadIdentifierKey: item.id])
                    // Store a json file in the same folder
                    do {
                        let json = try JSONEncoder().encode(item)
                        try json.write(to: destination.appendingPathComponent("description.json"))
                    } catch {}
                } catch let error {
                    // unzip error
                    NotificationCenter.default.post(name: Self.resourceError, object: nil, userInfo: [Self.downloadIdentifierKey: item.id, Self.resourceErrorKey: error])
                }
            }
        }
        let observation = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
            // Download progress
            NotificationCenter.default.post(name: Self.downloadProgress, object: nil, userInfo: [Self.downloadIdentifierKey: item.id, Self.downloadProgressKey: progress.fractionCompleted])
        }
        observations[item.id] = observation
        tasks[item.id] = downloadTask
        downloadTask.resume()
    }

    func cancel(identifier: String) {
        tasks.removeValue(forKey: identifier)?.cancel()
        observations.removeValue(forKey: identifier)?.invalidate()
    }

    func unzip(identifier: String, zipFilePath: URL) throws -> URL {
        guard let destinationURL = contextDirectory(forAddonWithIdentifier: identifier) else {
            throw ResourceManagerError.addonDirectoryNotExists
        }
        let fm = FileManager.default
        // We need to first move to a .zip path
        let movedPath = URL(fileURLWithPath: NSTemporaryDirectory() + "/\(UUID().uuidString).zip")
        try fm.moveItem(at: zipFilePath, to: movedPath)
        if !fm.fileExists(atPath: destinationURL.path) {
            try fm.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        }
        try fm.unzipItem(at: movedPath, to: destinationURL)
        return destinationURL
    }
}
