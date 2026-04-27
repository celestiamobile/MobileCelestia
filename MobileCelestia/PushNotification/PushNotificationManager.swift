// PushNotificationManager.swift
//
// Copyright (C) 2026-present, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import AsyncRequest
import CelestiaCore
import CelestiaFoundation
import CelestiaUI
import Foundation
import UIKit
import UserNotifications

private let pushAPIVersion = 1

private enum PushNotificationContentType: String, CaseIterable, Sendable {
    case weeklyAddon = "weekly-addon"
    case latestNews = "latest-news"
    case featuredAddon = "featured-addon"

    var userDefaultsKey: UserDefaultsKey {
        switch self {
        case .weeklyAddon: return .pushWeeklyAddon
        case .latestNews: return .pushLatestNews
        case .featuredAddon: return .pushFeaturedAddon
        }
    }
}

private extension UserDefaults {
    func pushTypeEnabled(_ type: PushNotificationContentType) -> Bool {
        // Defaults to true so newly-added types are enabled-by-default for opted-in users.
        return (self[type.userDefaultsKey] as String?) != "false"
    }

    func enabledPushContentTypes() -> [String] {
        return PushNotificationContentType.allCases
            .filter { pushTypeEnabled($0) }
            .map { $0.rawValue }
    }
}

@MainActor
final class PushNotificationManager {
    private let userDefaults: UserDefaults
    var presenter: () -> UIViewController? = { nil }
    private var deviceToken: String?

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func didReceiveDeviceToken(_ token: Data) {
        let hex = token.map { String(format: "%02x", $0) }.joined()
        deviceToken = hex
        userDefaults[.pushDeviceToken] = hex
        Task { await register() }
    }

    func didFailToRegister(_ error: Error) {
        // Token will retry on next launch via registerForRemoteNotifications.
    }

    func runFirstRunOrReregister() {
        Task {
            let granted = await currentAuthorizationGranted()
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
                return
            }
            let asked = (userDefaults[.pushNotificationsAsked] as String?) == "true"
            if !asked {
                await runFirstRun()
            }
            // Permission missing and we've already asked — don't reprompt.
        }
    }

    func handleTap(articleID: String?, addonID: String?) {
        if let articleID {
            postOpen(.windowURL(url: .guide(id: articleID), source: .pushNotification))
            return
        }
        if let addonID {
            postOpen(.windowURL(url: .addon(id: addonID), source: .pushNotification))
            return
        }
    }

    func clearDeliveredArticleNotifications(articleID: String) {
        Task {
            let center = UNUserNotificationCenter.current()
            let delivered = await center.deliveredNotifications()
            let identifiers = delivered
                .filter { ($0.request.content.userInfo["article-id"] as? String) == articleID }
                .map { $0.request.identifier }
            guard !identifiers.isEmpty else { return }
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
        }
    }

    func register() async {
        guard let token = deviceToken ?? (userDefaults[.pushDeviceToken] as String?) else { return }
        guard await currentAuthorizationGranted() else { return }

        let request = RegisterRequest(
            token: token,
            tokenType: currentTokenType,
            lang: AppCore.language,
            timezone: TimeZone.current.identifier,
            contentTypes: userDefaults.enabledPushContentTypes(),
            api: pushAPIVersion,
            platform: currentPlatform,
            distribution: nil,
            lastShownNewsID: userDefaults[.lastNewsID] as String?
        )
        do {
            try await AsyncEmptyRequestHandler.post(
                url: URL.apiPrefixURL.appendingPathComponent("users/register").absoluteString,
                json: request,
                httpClient: URLSession.shared
            )
        } catch {}
    }

    private func runFirstRun() async {
        guard let host = presenter() else { return }
        let confirmed: Bool = await withCheckedContinuation { continuation in
            host.showOption(
                CelestiaString("Stay Updated", comment: "Push notification opt-in dialog title"),
                message: CelestiaString(
                    "Receive notifications about featured add-ons and the latest news. You can change which kinds you receive in Settings.",
                    comment: "Push notification opt-in dialog message"
                )
            ) { ok in
                continuation.resume(returning: ok)
            }
        }
        userDefaults[.pushNotificationsAsked] = "true"
        guard confirmed else { return }
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        guard granted else { return }
        UIApplication.shared.registerForRemoteNotifications()
    }

    private func currentAuthorizationGranted() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    private var currentTokenType: String {
#if DEBUG
        return "apns-sandbox"
#else
        return "apns"
#endif
    }

    private var currentPlatform: String {
#if targetEnvironment(macCatalyst)
        return "catalyst"
#else
        return "ios"
#endif
    }

    private func postOpen(_ url: AppURL) {
        NotificationCenter.default.post(
            name: newURLOpenedNotificationName,
            object: nil,
            userInfo: [newURLOpenedNotificationURLKey: url]
        )
    }
}

private struct RegisterRequest: Encodable {
    let token: String
    let tokenType: String
    let lang: String
    let timezone: String
    let contentTypes: [String]
    let api: Int
    let platform: String
    let distribution: String?
    let lastShownNewsID: String?
}
