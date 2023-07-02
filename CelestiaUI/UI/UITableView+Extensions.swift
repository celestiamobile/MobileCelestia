//
// UITableView+Extensions.swift
//
// Copyright © 2021 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public extension UITableView.Style {
    static var defaultGrouped: UITableView.Style {
        #if targetEnvironment(macCatalyst)
        return .insetGrouped
        #else
        return .grouped
        #endif
    }
}
