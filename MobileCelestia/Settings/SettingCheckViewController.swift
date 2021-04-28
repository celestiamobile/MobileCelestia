//
// SettingCheckViewController.swift
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

class SettingCheckViewController: BaseTableViewController {
    struct Item {
        let title: String
        let masterKey: String?
        let subitems: [SettingCheckmarkItem]
    }

    private let item: Item

    init(item: Item) {
        self.item = item
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

private extension SettingCheckViewController {
    func setup() {
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(SettingSwitchCell.self, forCellReuseIdentifier: "Switch")
        title = item.title
    }
}

extension SettingCheckViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        let core = CelestiaAppCore.shared
        if item.masterKey != nil && (core.value(forKey: item.masterKey!) as! Bool) {
            return 2
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if item.masterKey != nil && section == 0 { return 1 }
        return item.subitems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let core = CelestiaAppCore.shared

        if item.masterKey != nil && indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath) as! SettingSwitchCell
            cell.title = item.title
            cell.enabled = core.value(forKey: item.masterKey!) as! Bool
            let key = item.masterKey!
            cell.toggleBlock = { [unowned self] (enabled) in
                let core = CelestiaAppCore.shared
                core.setValue(enabled, forKey: key)

                self.tableView.reloadData()
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        let subitem = item.subitems[indexPath.row]
        let title = subitem.name
        let enabled = (core.value(forKey: subitem.key) as! Bool)
        cell.title = title
        cell.accessoryType = enabled ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if item.masterKey != nil && indexPath.section == 0 {
            return
        }

        let core = CelestiaAppCore.shared

        let subitem = item.subitems[indexPath.row]
        let key = subitem.key
        let enabled = (core.value(forKey: subitem.key) as! Bool)
        core.setValue(!enabled, forKey: key)
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
