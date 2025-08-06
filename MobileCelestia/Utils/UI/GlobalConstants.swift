// GlobalConstants.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI

extension GlobalConstants {
    static let listItemSmallMarginHorizontal: CGFloat = 12
    static let listItemSmallMarginVertical: CGFloat = 8

    static let listItemSeparatorInsetLeading: CGFloat = 16

    static let bottomControlViewItemDimension: CGFloat = 48
    static let bottomControlViewItemPadding: CGFloat = 10
    static let bottomControlViewMarginHorizontal: CGFloat = 4
    static let bottomControlViewMarginVertical: CGFloat = 0
    static let bottomControlViewDimension: CGFloat = 48
    static let bottomControlContainerCornerRadius: CGFloat = 8

    #if targetEnvironment(macCatalyst)
    static let actionMenuItemCornerRadius: CGFloat = 12
    #endif

    static let transitionDuration: TimeInterval = 0.2
}
