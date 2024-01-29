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
import Foundation

public enum GameControllerAction: Int, CaseIterable {
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

    public var name: String {
        switch self {
        case .noop:
            return CelestiaString("None", comment: "Empty HUD display")
        case .moveFaster:
            return CelestiaString("Travel Faster", comment: "Game controller action")
        case .moveSlower:
            return CelestiaString("Travel Slower", comment: "Game controller action")
        case .stopSpeed:
            return CelestiaString("Stop", comment: "Interupt the process of finding eclipse/Set traveling speed to 0")
        case .reverseSpeed:
            return CelestiaString("Reverse Travel Direction", comment: "Game controller action")
        case .reverseOrientation:
            return CelestiaString("Reverse Observer Orientation", comment: "Game controller action")
        case .tapCenter:
            return CelestiaString("Tap Center", comment: "Game controller action")
        case .goTo:
            return CelestiaString("Go to Object", comment: "")
        case .esc:
            return CelestiaString("Esc", comment: "Game controller action")
        case .pitchUp:
            return CelestiaString("Pitch Up", comment: "Game controller action")
        case .pitchDown:
            return CelestiaString("Pitch Down", comment: "Game controller action")
        case .yawLeft:
            return CelestiaString("Yaw Left", comment: "Game controller action")
        case .yawRight:
            return CelestiaString("Yaw Right", comment: "Game controller action")
        case .rollLeft:
            return CelestiaString("Roll Left", comment: "Game controller action")
        case .rollRight:
            return CelestiaString("Roll Right", comment: "Game controller action")
        }
    }
}
