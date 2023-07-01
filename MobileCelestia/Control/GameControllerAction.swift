//
// GameControllerAction.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import CelestiaUI
import Foundation

enum GameControllerAction: Int, CaseIterable {
    case noop
    case moveFaster
    case moveSlower
    case stopSpeed
    case reverseSpeed
    case reverseOrientation
    case tapCenter
    case goTo
    case esc
    case pitchUp
    case pitchDown
    case yawLeft
    case yawRight
    case rollLeft
    case rollRight

    var name: String {
        switch self {
        case .noop:
            return CelestiaString("None", comment: "")
        case .moveFaster:
            return CelestiaString("Travel Faster", comment: "")
        case .moveSlower:
            return CelestiaString("Travel Slower", comment: "")
        case .stopSpeed:
            return CelestiaString("Stop", comment: "")
        case .reverseSpeed:
            return CelestiaString("Reverse Travel Direction", comment: "")
        case .reverseOrientation:
            return CelestiaString("Reverse Observer Orientation", comment: "")
        case .tapCenter:
            return CelestiaString("Tap Center", comment: "")
        case .goTo:
            return CelestiaString("Go to Object", comment: "")
        case .esc:
            return CelestiaString("Esc", comment: "")
        case .pitchUp:
            return CelestiaString("Pitch Up", comment: "")
        case .pitchDown:
            return CelestiaString("Pitch Down", comment: "")
        case .yawLeft:
            return CelestiaString("Yaw Left", comment: "")
        case .yawRight:
            return CelestiaString("Yaw Right", comment: "")
        case .rollLeft:
            return CelestiaString("Roll Left", comment: "")
        case .rollRight:
            return CelestiaString("Roll Right", comment: "")
        }
    }
}
