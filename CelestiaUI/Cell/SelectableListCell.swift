//
// SelectableListCell.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public class SelectableListCell: UICollectionViewListCell {
    public var selectable: Bool = true {
        didSet {
            guard selectable != oldValue else { return }
            setNeedsUpdateConfiguration()
        }
    }

    public enum BackgroundStyle {
        case grouped
        case plain
        case clear
    }

    public var backgroundStyle: BackgroundStyle = .grouped {
        didSet {
            guard backgroundStyle != oldValue else { return }
            setNeedsUpdateConfiguration()
        }
    }

    public override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)

        var stateToUpdate = state
        if !selectable {
            stateToUpdate.isHighlighted = false
            stateToUpdate.isSelected = false
        }
        var configuration: UIBackgroundConfiguration
        switch backgroundStyle {
        case .grouped:
            configuration = .listGroupedCell()
        case .plain:
            configuration = .listPlainCell()
        case .clear:
            configuration = .clear()
        }
        configuration = configuration.updated(for: stateToUpdate)
        // set the color explicitly so default is not used
        configuration.backgroundColor = configuration.backgroundColor
        backgroundConfiguration = configuration
    }
}
