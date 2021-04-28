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

class BaseTableViewController: UITableViewController {
    override func loadView() {
        super.loadView()

        tableView.backgroundColor = .darkBackground
        tableView.alwaysBounceVertical = false
        tableView.separatorColor = .darkSeparator
        tableView.estimatedRowHeight = 44
    }
}
