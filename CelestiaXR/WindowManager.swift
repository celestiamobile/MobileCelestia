//
// WindowState.swift
//
// Copyright © 2024 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation
import Observation

@Observable class WindowManager {
    enum Tool {
        case none
        case browser
        case search
        case installedAddons
        case downloadAddons
        case goTo
        case eclipseFinder
        case cameraControl
        case favorites
        case settings
        case currentTime
        case help
    }

    var tool: Tool = .none

    @ObservationIgnored
    var isToolWindowVisible: Bool = false

    @ObservationIgnored
    var isStartUpWindowVisible: Bool = false

    @ObservationIgnored
    var isInfoWindowVisible: Bool = false
}
