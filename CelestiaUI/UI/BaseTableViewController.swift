//
// BaseTableViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

open class BaseTableViewController: UITableViewController {
    public override func loadView() {
        super.loadView()

        if tableView.style == .plain {
            tableView.backgroundColor = .darkBackground
        } else if tableView.style == .grouped {
            tableView.backgroundColor = .darkGroupedBackground
        } else if #available(iOS 13.0, *), tableView.style == .insetGrouped {
            tableView.backgroundColor = .darkGroupedBackground
        }
        tableView.alwaysBounceVertical = false
        tableView.separatorColor = .darkSeparator
        tableView.estimatedRowHeight = GlobalConstants.baseCellHeight
    }
}
