// GlobalConstants.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CoreGraphics
import UIKit

public enum GlobalConstants {
    public static let listItemMediumMarginHorizontal: CGFloat = 16
    public static let listItemMediumMarginVertical: CGFloat = 12
    public static let listItemGapHorizontal: CGFloat = 8
    public static let listItemGapVertical: CGFloat = 8
    static let listItemPopUpButtonMarginHorizontal: CGFloat = {
        #if targetEnvironment(macCatalyst)
        return listItemMediumMarginHorizontal
        #else
        return 4
        #endif
    }()

    public static let listItemAccessoryMinMarginVertical: CGFloat = 6

    public static let listTextGapVertical: CGFloat = 4

    public static let pageMediumMarginHorizontal: CGFloat = 16
    public static let pageMediumMarginVertical: CGFloat = 12
    public static let pageMediumGapHorizontal: CGFloat = 12
    public static let pageMediumGapVertical: CGFloat = 8
    public static let pageSmallMarginHorizontal: CGFloat = 12
    public static let pageSmallMarginVertical: CGFloat = 8
    public static let pageLargeGapHorizontal: CGFloat = 16
    public static let pageSmallGapHorizontal: CGFloat = 6
    public static let pageSmallGapVertical: CGFloat = 4

    public static let listItemIconSize: CGFloat = 24

    public static let pageLargeGapVertical: CGFloat = 12

    public static let baseCellHeight: CGFloat = 44

    static let cardCornerRadius: CGFloat = 12
    static let cardContentPadding: CGFloat = 16

    public static func preferredUIElementScaling(for traitCollection: UITraitCollection) -> CGFloat {
        #if targetEnvironment(macCatalyst)
        // Mac idiom, needs scaling
        return 0.77
        #else
        return 1
        #endif
    }
}
