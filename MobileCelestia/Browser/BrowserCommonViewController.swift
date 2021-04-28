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

import UIKit

import CelestiaCore

class BrowserCommonViewController: BaseTableViewController {
    private let item: CelestiaBrowserItem

    private let selection: (CelestiaBrowserItem, Bool) -> Void

    init(item: CelestiaBrowserItem, selection: @escaping (CelestiaBrowserItem, Bool) -> Void) {
        self.item = item
        self.selection = selection
        super.init(style: .defaultGrouped)
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
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        title = item.alternativeName ?? item.name
    }
}

extension BrowserCommonViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        if item.entry != nil { return 2 }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if item.entry != nil && section == 0 { return 1 }
        return item.children.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
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
