//
// CelestiaAction.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import Foundation

public enum CelestiaAction: Int8 {
    case goTo = 103
    case goToSurface = 7
    case center = 99
    case playpause = 32
    case reverse = 106
    case slower = 107
    case faster = 108
    case currentTime = 33
    case syncOrbit = 121
    case lock = 58
    case chase = 34
    case follow = 102
    case runDemo = 100
    case cancelScript = 27
    case home = 104
    case track = 116
    case stop = 115
    case reverseSpeed = 113
}

public extension CelestiaAction {
    static var allCases: [CelestiaAction] {
        return [.goTo, .center, .follow, .chase, .track, .syncOrbit, .lock, .goToSurface]
    }
}
