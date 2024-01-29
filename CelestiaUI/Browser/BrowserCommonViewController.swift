//
// BrowserCommonViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

class BrowserCommonViewController: BaseTableViewController {
    private let item: BrowserItem

    private let selection: (BrowserItem, Bool) -> Void

    init(item: BrowserItem, selection: @escaping (BrowserItem, Bool) -> Void) {
        self.item = item
        self.selection = selection
        super.init(style: .defaultGrouped)
        title = item.alternativeName ?? item.name
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension BrowserCommonViewController {
    func setup() {
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
    }
}

extension BrowserCommonViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        if item.entry != nil { return item.children.isEmpty ? 1 : 2 }
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return nil }
        return CelestiaString("Subsystem", comment: "Subsystem of an object (e.g. planetarium system)")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if item.entry != nil && section == 0 { return 1 }
        return item.children.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
        if item.entry != nil && indexPath.section == 0 {
            cell.title = item.name
            cell.accessoryType = .none
        } else {
            let subitem = item.children[indexPath.row]
            cell.title = subitem.name
            cell.accessoryType = subitem.children.count == 0 ? .none : .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if item.entry != nil && indexPath.section == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            selection(item, true)
        } else {
            let subitem = item.children[indexPath.row]
            let isLeaf = subitem.children.count == 0
            if isLeaf {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            selection(subitem, isLeaf)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
