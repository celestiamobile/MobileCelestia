//
// NotificationService.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

@preconcurrency import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        let bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent) ?? UNMutableNotificationContent()
        self.bestAttemptContent = bestAttemptContent

        guard let urlString = bestAttemptContent.userInfo["image-url"] as? String,
              let url = URL(string: urlString) else {
            contentHandler(bestAttemptContent)
            return
        }

        let sendableContentHandler = unsafeBitCast(contentHandler, to: (@Sendable (UNNotificationContent) -> Void).self)
        URLSession.shared.downloadTask(with: url) { tempURL, response, _ in
            if let tempURL {
                let suggestedExtension = (response?.suggestedFilename as NSString?)?.pathExtension
                let pathExtension = (suggestedExtension?.isEmpty == false ? suggestedExtension : url.pathExtension) ?? "tmp"
                let destination = tempURL.deletingLastPathComponent().appendingPathComponent("\(UUID().uuidString).\(pathExtension)")
                do {
                    try FileManager.default.moveItem(at: tempURL, to: destination)
                    let attachment = try UNNotificationAttachment(identifier: "", url: destination)
                    bestAttemptContent.attachments = [attachment]
                } catch {}
            }
            sendableContentHandler(bestAttemptContent)
        }.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        // Apple gives the extension a finite window (~30s) before falling back
        // to the original payload — emit whatever we have.
        if let contentHandler, let bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
