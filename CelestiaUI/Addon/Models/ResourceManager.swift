// ResourceManager.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation
import ZipUtils

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
        // Parse script folder first, because add-on folder might need migration
        if let scriptDirectory = extraScriptDirectory, let folders = try? fm.contentsOfDirectory(atPath: scriptDirectory.path) {
            for folder in folders {
                let descriptionFile = scriptDirectory.appendingPathComponent(folder).appendingPathComponent("description.json")
                if let data = try? Data(contentsOf: descriptionFile),
                   let content = try? JSONDecoder().decode(ResourceItem.self, from: data),
                   content.id == folder, content.type == "script" {
                    items.append(content)
                }
            }
        }
        if let addonDirectory = extraAddonDirectory, let folders = try? fm.contentsOfDirectory(atPath: addonDirectory.path) {
            for folder in folders {
                let folderURL = addonDirectory.appendingPathComponent(folder)
                let descriptionFile = folderURL.appendingPathComponent("description.json")
                if let data = try? Data(contentsOf: descriptionFile),
                   let content = try? JSONDecoder().decode(ResourceItem.self, from: data),
                   content.id == folder, content.type != "script" {
                    items.append(content)
                }
            }
        }
        return items.sorted(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending })
    }

    func uninstall(item: ResourceItem) throws {
        guard let folder = contextDirectory(forAddon: item) else { return }
        try FileManager.default.removeItem(at: folder)
    }

    func download(item: ResourceItem) {
        guard let destinationURL = contextDirectory(forAddon: item) else { return }

        let downloadTask = URLSession.shared.downloadTask(with: item.item) { [weak self] url, response, error in
            guard let self else { return }
            self.handleDownloadResult(item: item, url: url, response: response, error: error, destinationURL: destinationURL)
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

    private nonisolated func handleDownloadResult(url: URL?, response: URLResponse?, error: Error?) throws -> URL {
        if let e = error {
            throw e
        }
        // We have to move immediately after the download task
        return try moveTemporaryFile(url: url!)
    }

    private nonisolated func handleDownloadResult(item: ResourceItem, url: URL?, response: URLResponse?, error: Error?, destinationURL: URL) {
        let tempURL: URL
        do {
            tempURL = try handleDownloadResult(url: url, response: response, error: error)
        } catch {
            Task { @MainActor in
                self.tasks.removeValue(forKey: item.id)
                self.observations.removeValue(forKey: item.id)?.invalidate()

                if let e = error as? URLError, e.errorCode == URLError.cancelled.rawValue {
                    // Canceled
                    NotificationCenter.default.post(name: Self.resourceError, object: nil, userInfo: [Self.downloadIdentifierKey: item.id, Self.resourceErrorKey: ResourceError.cancelled])
                } else {
                    // Download error or moving to temp location error
                    NotificationCenter.default.post(name: Self.resourceError, object: nil, userInfo: [Self.downloadIdentifierKey: item.id, Self.resourceErrorKey: ResourceError.download])
                }
            }
            return
        }

        // Download and move success
        Task { @MainActor in
            self.tasks.removeValue(forKey: item.id)
            self.observations.removeValue(forKey: item.id)?.invalidate()

            NotificationCenter.default.post(name: Self.downloadSuccess, object: nil, userInfo: [Self.downloadIdentifierKey: item.id])
            do {
                try await self.unzip(zipFileURL: tempURL, destinationURL: destinationURL)
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

    private nonisolated func moveTemporaryFile(url: URL) throws -> URL {
        let fm = FileManager.default
        let movedURL = try URL.temp(for: url).appendingPathComponent("\(UUID().uuidString).zip")
        try fm.moveItem(at: url, to: movedURL)
        return movedURL
    }

    enum ResourceError: Error {
        case cancelled
        case download
        case zip
        case createDirectory(contextPath: String)
        case openFile(contextPath: String)
        case writeFile(contextPath: String)
    }

    private nonisolated func unzip(zipFileURL: URL, destinationURL: URL) async throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: destinationURL.path) {
            do {
                try fm.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                throw ResourceError.createDirectory(contextPath: destinationURL.path)
            }
        }
        try await Task.detached(priority: .background) {
            do {
                try ZipUtils.unzip(zipFileURL.path, to: destinationURL.path)
            } catch {
                if let e = error as? CEZZipError {
                    switch e.code {
                    case .createDirectory:
                        throw ResourceError.createDirectory(contextPath: e.userInfo[CEZZipErrorContextPathKey] as? String ?? "")
                    case .openFile:
                        throw ResourceError.openFile(contextPath: e.userInfo[CEZZipErrorContextPathKey] as? String ?? "")
                    case .writeFile:
                        throw ResourceError.writeFile(contextPath: e.userInfo[CEZZipErrorContextPathKey] as? String ?? "")
                    case .zip:
                        throw ResourceError.zip
                    @unknown default:
                        throw ResourceError.zip
                    }
                } else {
                    throw ResourceError.zip
                }
            }
        }.value
    }
}
