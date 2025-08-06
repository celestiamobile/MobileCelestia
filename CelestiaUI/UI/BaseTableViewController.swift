// BaseTableViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

open class BaseTableViewController: UITableViewController {
    public override func loadView() {
        super.loadView()
        #if !os(visionOS)
        if tableView.style == .plain {
            tableView.backgroundColor = .systemBackground
        } else if tableView.style == .grouped {
            tableView.backgroundColor = .systemGroupedBackground
        } else if tableView.style == .insetGrouped {
            tableView.backgroundColor = .systemGroupedBackground
        }
        #endif
        tableView.separatorColor = .separator
        tableView.estimatedRowHeight = GlobalConstants.baseCellHeight
    }
}
