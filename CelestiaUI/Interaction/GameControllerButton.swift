//
// GameControllerButton.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaFoundation
import Foundation

public enum GameControllerButton {
    case A
    case B
    case X
    case Y
    case LT
    case RT
    case LB
    case RB
    case dpadLeft
    case dpadRight
    case dpadUp
    case dpadDown
}

public extension GameControllerButton {
    var userDefaultsKey: UserDefaultsKey {
        switch self {
        case .A:
            return .gameControllerRemapA
        case .B:
            return .gameControllerRemapB
        case .X:
            return .gameControllerRemapX
        case .Y:
            return .gameControllerRemapY
        case .LT:
            return .gameControllerRemapLT
        case .RT:
            return .gameControllerRemapRT
        case .LB:
            return .gameControllerRemapLB
        case .RB:
            return .gameControllerRemapRB
        case .dpadLeft:
            return .gameControllerRemapDpadLeft
        case .dpadRight:
            return .gameControllerRemapDpadRight
        case .dpadUp:
            return .gameControllerRemapDpadUp
        case .dpadDown:
            return .gameControllerRemapDpadDown
        }
    }
}
