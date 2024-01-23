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
import UIKit

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
    case cancelScript = 27
    case home = 104
    case track = 116
    case stop = 115
    case reverseSpeed = 113
}

public enum CelestiaContinuousAction: Int {
    case travelFaster = 97
    case travelSlower = 122
    case f1 = 11
    case f2 = 12
    case f3 = 13
    case f4 = 14
    case f5 = 15
    case f6 = 16
    case f7 = 17
}

public extension CelestiaAction {
    static var allCases: [CelestiaAction] {
        return [.goTo, .center, .follow, .chase, .track, .syncOrbit, .lock, .goToSurface]
    }
}

public extension CelestiaAction {
    var image: UIImage? {
        switch self {
        case .playpause:
            return UIImage(systemName: "playpause.fill")
        case .faster:
            return UIImage(systemName: "forward.fill")
        case .slower:
            return UIImage(systemName: "backward.fill")
        case .reverse, .reverseSpeed:
            return UIImage(systemName: "repeat")?.withConfiguration(UIImage.SymbolConfiguration(weight: .black))
        case .cancelScript, .stop:
            return UIImage(systemName: "stop.fill")
        default:
            return nil
        }
    }

    var description: String {
        switch self {
        case .goTo:
            return CelestiaString("Go", comment: "")
        case .goToSurface:
            return CelestiaString("Land", comment: "")
        case .center:
            return CelestiaString("Center", comment: "")
        case .playpause:
            return CelestiaString("Resume/Pause", comment: "")
        case .slower:
            return CelestiaString("Slower", comment: "")
        case .faster:
            return CelestiaString("Faster", comment: "")
        case .reverse:
            return CelestiaString("Reverse Time", comment: "")
        case .currentTime:
            return CelestiaString("Current Time", comment: "")
        case .syncOrbit:
            return CelestiaString("Sync Orbit", comment: "")
        case .lock:
            return CelestiaString("Lock", comment: "")
        case .chase:
            return CelestiaString("Chase", comment: "")
        case .track:
            return CelestiaString("Track", comment: "")
        case .follow:
            return CelestiaString("Follow", comment: "")
        case .cancelScript:
            return CelestiaString("Cancel Script", comment: "")
        case .home:
            return CelestiaString("Home (Sol)", comment: "")
        case .stop:
            return CelestiaString("Stop", comment: "")
        case .reverseSpeed:
            return CelestiaString("Reverse Direction", comment: "")
        }
    }
}

public extension CelestiaContinuousAction {
    var image: UIImage? {
        switch self {
        case .travelFaster:
            return UIImage(systemName: "forward.fill")
        case .travelSlower:
            return UIImage(systemName: "backward.fill")
        default:
            return nil
        }
    }

    var title: String? {
        switch self {
        case .f2:
            return CelestiaString("1 km/s", comment: "")
        case .f3:
            return CelestiaString("1000 km/s", comment: "")
        case .f4:
            return CelestiaString("c (lightspeed)", comment: "")
        case .f5:
            return CelestiaString("10c", comment: "")
        case .f6:
            return CelestiaString("1 AU/s", comment: "")
        case .f7:
            return CelestiaString("1 ly/s", comment: "")
        default:
            return nil
        }
    }
}
