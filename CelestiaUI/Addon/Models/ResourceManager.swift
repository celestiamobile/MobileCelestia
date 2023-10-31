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

@MainActor
public final class ResourceManager: @unchecked Sendable {
    private let extraAddonDirectory: URL?
    private let extraScriptDirectory: URL?

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

    public init(extraAddonDirectory: URL?, extraScriptDirectory: URL?) {
        self.extraAddonDirectory = extraAddonDirectory
        self.extraScriptDirectory = extraScriptDirectory
    }

    func isDownloading(identifier: String) -> Bool {
        return tasks[identifier] != nil
    }

    func isInstalled(item: ResourceItem) -> Bool {
        guard let directory = contextDirectory(forAddon: item) else { return false }
        return FileManager.default.fileExists(atPath: directory.path)
    }

    func contextDirectory(forAddon item: ResourceItem) -> URL? {
        if item.type == "script" {
            return extraScriptDirectory?.appendingPathComponent(item.id)
        }
        return extraAddonDirectory?.appendingPathComponent(item.id)
    }

    public nonisolated func installedResources() -> [ResourceItem] {
        var items = [ResourceItem]()
        let fm = FileManager.default
        var trackedIds = Set<String>()
        // Parse script folder first, because add-on folder might need migration
        if let addonDirectory = extraScriptDirectory {
            guard let folders = try? fm.contentsOfDirectory(atPath: addonDirectory.path) else { return [] }
            for folder in folders {
                let descriptionFile = addonDirectory.appendingPathComponent(folder).appendingPathComponent("description.json")
                if let data = try? Data(contentsOf: descriptionFile),
                   let content = try? JSONDecoder().decode(ResourceItem.self, from: data),
                   content.id == folder, content.type == "script" {
                    items.append(content)
                    trackedIds.insert(content.id)
                }
            }
        }
        if let scriptDirectory = extraScriptDirectory {
            guard let folders = try? fm.contentsOfDirectory(atPath: scriptDirectory.path) else { return [] }
            for folder in folders {
                let folderURL = scriptDirectory.appendingPathComponent(folder)
                let descriptionFile = folderURL.appendingPathComponent("description.json")
                if let data = try? Data(contentsOf: descriptionFile),
                   let content = try? JSONDecoder().decode(ResourceItem.self, from: data),
                   content.id == folder, !trackedIds.contains(content.id) {
                    if content.type == "script" {
                        // Perform migration by moving folder to scripts folder
                        do {
                            try fm.moveItem(at: folderURL, to: scriptDirectory.appendingPathComponent(content.id))
                            items.append(content)
                        } catch {}
                    } else {
                        items.append(content)
                    }
                }
            }
        }
        return items
    }

    func uninstall(item: ResourceItem) throws {
        guard let folder = contextDirectory(forAddon: item) else { return }
        try FileManager.default.removeItem(at: folder)
    }

    func download(item: ResourceItem) {
        let downloadTask = URLSession.shared.downloadTask(with: item.item) { [weak self] url, response, error in
            guard let self else { return }
            Task.detached { @MainActor in
                await self.handleDownloadResult(item: item, url: url, response: response, error: error)
            }
        }
        let observation = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
            // Download progress
            Task.detached { @MainActor in
                NotificationCenter.default.post(name: Self.downloadProgress, object: nil, userInfo: [Self.downloadIdentifierKey: item.id, Self.downloadProgressKey: progress.fractionCompleted])
            }
        }
        observations[item.id] = observation
        tasks[item.id] = downloadTask
        downloadTask.resume()
    }

    func cancel(identifier: String) {
        tasks.removeValue(forKey: identifier)?.cancel()
        observations.removeValue(forKey: identifier)?.invalidate()
    }

    func handleDownloadResult(item: ResourceItem, url: URL?, response: URLResponse?, error: Error?) async {
        tasks.removeValue(forKey: item.id)
        observations.removeValue(forKey: item.id)?.invalidate()

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
                guard let destinationURL = contextDirectory(forAddon: item) else {
                    throw ResourceManagerError.addonDirectoryNotExists
                }
                try await unzip(zipFileURL: url!, destinationURL: destinationURL)
                NotificationCenter.default.post(name: Self.unzipSuccess, object: nil, userInfo: [Self.downloadIdentifierKey: item.id])
                // Store a json file in the same folder
                do {
                    let json = try JSONEncoder().encode(item)
                    try await json.write(to: destinationURL.appendingPathComponent("description.json"))
                } catch {}
            } catch let error {
                // unzip error
                NotificationCenter.default.post(name: Self.resourceError, object: nil, userInfo: [Self.downloadIdentifierKey: item.id, Self.resourceErrorKey: error])
            }
        }
    }

    nonisolated func unzip(zipFileURL: URL, destinationURL: URL) async throws {
        let fm = FileManager.default
        // We need to first move to a .zip path
        let movedPath = URL(fileURLWithPath: NSTemporaryDirectory() + "/\(UUID().uuidString).zip")
        try fm.moveItem(at: zipFileURL, to: movedPath)
        if !fm.fileExists(atPath: destinationURL.path) {
            try fm.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        }
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    try FileManager.default.unzipItem(at: movedPath, to: destinationURL)
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
