// FeatureFlags.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation

public struct FeatureFlags: Sendable {
    public let dummy: Bool
    public let swiftUITimeSettings: Bool
    public let iosGLESV3: Bool
    public let pushNotificationIOS: Bool

    public init(
        dummy: Bool = false,
        swiftUITimeSettings: Bool = false,
        iosGLESV3: Bool = false,
        pushNotificationIOS: Bool = false
    ) {
        self.dummy = dummy
        self.swiftUITimeSettings = swiftUITimeSettings
        self.iosGLESV3 = iosGLESV3
        self.pushNotificationIOS = pushNotificationIOS
    }
}
