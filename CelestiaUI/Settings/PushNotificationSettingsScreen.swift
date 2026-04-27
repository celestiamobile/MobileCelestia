// PushNotificationSettingsScreen.swift
//
// Copyright (C) 2026-present, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#if !os(visionOS)

import CelestiaFoundation
import SwiftUI
import UIKit
import UserNotifications

struct PushNotificationSettingsScreen: View {
    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var weeklyAddon: Bool
    @State private var latestNews: Bool
    @State private var featuredAddon: Bool

    private let userDefaults: UserDefaults
    private let onSave: () -> Void
    private let openSystemSettings: () -> Void

    init(userDefaults: UserDefaults, onSave: @escaping () -> Void, openSystemSettings: @escaping () -> Void) {
        self.userDefaults = userDefaults
        self.onSave = onSave
        self.openSystemSettings = openSystemSettings
        _weeklyAddon = State(initialValue: (userDefaults[.pushWeeklyAddon] as String?) != "false")
        _latestNews = State(initialValue: (userDefaults[.pushLatestNews] as String?) != "false")
        _featuredAddon = State(initialValue: (userDefaults[.pushFeaturedAddon] as String?) != "false")
    }

    var body: some View {
        Form {
            switch status {
            case .denied:
                Section {
                    Text(CelestiaString("Notifications are turned off for Celestia. Enable them in Settings to subscribe to updates.", comment: "Push notification denied state explanation"))
                        .foregroundStyle(.secondary)
                    Button(CelestiaString("Open System Settings", comment: "Push notification denied state action")) {
                        openSystemSettings()
                    }
                }
            case .authorized, .provisional, .ephemeral, .notDetermined:
                Section {
                    Toggle(CelestiaString("Weekly Add-on", comment: "Push notification content type — weekly featured add-on"), isOn: $weeklyAddon)
                    Toggle(CelestiaString("Featured Add-on", comment: "Push notification content type — featured add-on"), isOn: $featuredAddon)
                    Toggle(CelestiaString("Latest News", comment: "Push notification content type — latest news"), isOn: $latestNews)
                }
                Section {
                    Button(CelestiaString("Save", comment: "Save push notification preferences")) {
                        userDefaults[.pushWeeklyAddon] = weeklyAddon ? "true" : "false"
                        userDefaults[.pushLatestNews] = latestNews ? "true" : "false"
                        userDefaults[.pushFeaturedAddon] = featuredAddon ? "true" : "false"
                        onSave()
                    }
                }
            @unknown default:
                EmptyView()
            }
        }
        .task {
            await refreshStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await refreshStatus() }
        }
    }

    private func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let newStatus = settings.authorizationStatus
        if newStatus != status && (newStatus == .authorized || newStatus == .provisional) {
            // User came back from system settings with permission granted —
            // sync prefs to the server so the row is accurate.
            UIApplication.shared.registerForRemoteNotifications()
            onSave()
        }
        status = newStatus
    }
}

class PushNotificationSettingsViewController: UIHostingController<PushNotificationSettingsScreen> {
    init(userDefaults: UserDefaults, onSave: @escaping () -> Void, openSystemSettings: @escaping () -> Void) {
        super.init(rootView: PushNotificationSettingsScreen(userDefaults: userDefaults, onSave: onSave, openSystemSettings: openSystemSettings))
        title = CelestiaString("Notifications", comment: "Push notification settings entry")
        windowTitle = title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
