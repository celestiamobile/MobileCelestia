// List+Extensions.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

public extension UICollectionLayoutListConfiguration.Appearance {
    static var defaultGrouped: Self {
        #if targetEnvironment(macCatalyst)
        return .insetGrouped
        #else
        return .grouped
        #endif
    }
}

public extension UIListContentConfiguration {
    static func celestiaCell() -> Self {
        var configuration = cell()
        configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: GlobalConstants.listItemMediumMarginVertical, leading: GlobalConstants.listItemMediumMarginHorizontal, bottom: GlobalConstants.listItemMediumMarginVertical, trailing: GlobalConstants.listItemMediumMarginHorizontal)
        return configuration
    }

    static func celestiaValueCell() -> Self {
        var configuration = valueCell()
        configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: GlobalConstants.listItemMediumMarginVertical, leading: GlobalConstants.listItemMediumMarginHorizontal, bottom: GlobalConstants.listItemMediumMarginVertical, trailing: GlobalConstants.listItemMediumMarginHorizontal)
        return configuration
    }
}
