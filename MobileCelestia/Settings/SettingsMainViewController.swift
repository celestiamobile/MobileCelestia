//
// SettingsMainViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import UIKit

class SettingsMainViewController: BaseTableViewController {
    private let selection: (SettingItem<AnyHashable>) -> Void

    init(selection: @escaping (SettingItem<AnyHashable>) -> Void) {
        self.selection = selection
        #if targetEnvironment(macCatalyst)
        super.init(style: .grouped)
        #else
        super.init(style: .defaultGrouped)
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension SettingsMainViewController {
    func setup() {
        #if targetEnvironment(macCatalyst)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Text")
        #else
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        #endif
        title = CelestiaString("Settings", comment: "")
    }
}

extension SettingsMainViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return mainSetting.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mainSetting[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = mainSetting[indexPath.section].items[indexPath.row]
        #if targetEnvironment(macCatalyst)
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath)
        if #available(iOS 14.0, *) {
            var configuration = UIListContentConfiguration.sidebarCell()
            configuration.text = item.name
            cell.contentConfiguration = configuration
        } else {
            cell.textLabel?.text = item.name
        }
        #else
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = item.name
        cell.accessoryType = .disclosureIndicator
        #endif
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return mainSetting[section].title
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selection(mainSetting[indexPath.section].items[indexPath.row])
    }
}
