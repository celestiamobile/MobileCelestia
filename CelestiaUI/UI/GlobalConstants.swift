//
// GlobalConstants.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CoreGraphics
import UIKit

public enum GlobalConstants {
    public static let pageMediumMarginHorizontal: CGFloat = 16
    public static let pageMediumMarginVertical: CGFloat = 12
    public static let pageMediumGapHorizontal: CGFloat = 12
    public static let pageMediumGapVertical: CGFloat = 8

    public static func preferredUIElementScaling(for traitCollection: UITraitCollection) -> CGFloat {
        #if targetEnvironment(macCatalyst)
        if #available(iOS 14.0, *) {
            // Mac idiom, needs scaling
            if traitCollection.userInterfaceIdiom == .mac {
                return 0.77
            }
            // iPad idiom no need for scaling
            return 1
        }
        // macCatalyst 13, only iPad idiom is available
        return 1
        #else
        return 1
        #endif
    }
}
