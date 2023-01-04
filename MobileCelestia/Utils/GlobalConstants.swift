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

enum GlobalConstants {
    static let listItemMediumMarginHorizontal: CGFloat = 16
    static let listItemMediumMarginVertical: CGFloat = 12
    static let listItemSmallMarginHorizontal: CGFloat = 12
    static let listItemSmallMarginVertical: CGFloat = 8
    static let listItemGapHorizontal: CGFloat = 8
    static let listItemGapVertical: CGFloat = 8

    static let pageMediumMarginHorizontal: CGFloat = 16
    static let pageMediumMarginVertical: CGFloat = 12
    static let pageSmallMarginHorizontal: CGFloat = 12
    static let pageSmallMarginVertical: CGFloat = 8
    static let pageLargeGapHorizontal: CGFloat = 16
    static let pageLargeGapVertical: CGFloat = 12
    static let pageMediumGapHorizontal: CGFloat = 12
    static let pageMediumGapVertical: CGFloat = 8
    static let pageSmallGapHorizontal: CGFloat = 6
    static let pageSmallGapVertical: CGFloat = 4

    static let listTextGapVertical: CGFloat = 4

    static let listItemAccessoryMinMarginVertical: CGFloat = 6

    static let listItemSeparatorHeight: CGFloat = 0.5
    static let listItemSeparatorInsetLeading: CGFloat = 16

    static let bottomControlViewItemDimension: CGFloat = 52
    static let bottomControlViewMarginHorizontal: CGFloat = 4
    static let bottomControlViewMarginVertical: CGFloat = 2
    static let bottomControlViewDimension: CGFloat = 60
    static let bottomControlContainerCornerRadius: CGFloat = 8

    static let baseCellHeight: CGFloat = 44

    static let timeSliderViewDefaultTickLength: CGFloat = 2
    static let timeSliderViewBaseHeight: CGFloat = 40
    static let timeSliderViewMarginHorizontal: CGFloat = 8

    static func preferredUIElementScaling(for traitCollection: UITraitCollection) -> CGFloat {
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
