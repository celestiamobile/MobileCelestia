//
// SettingsMainViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class SettingsMainViewController: BaseTableViewController {
    private let sections: [SettingSection]
    private let selection: (SettingItem) async -> Void

    init(sections: [SettingSection], selection: @escaping (SettingItem) async -> Void) {
        self.sections = sections
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

        setUp()
    }
}

private extension SettingsMainViewController {
    func setUp() {
        #if targetEnvironment(macCatalyst)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Text")
        #else
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        #endif
        title = CelestiaString("Settings", comment: "")
    }
}

extension SettingsMainViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        #if targetEnvironment(macCatalyst)
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath)
        var configuration = UIListContentConfiguration.sidebarCell()
        configuration.text = item.name
        cell.contentConfiguration = configuration
        #else
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
        cell.title = item.name
        cell.accessoryType = .disclosureIndicator
        #endif
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Task {
            await selection(sections[indexPath.section].items[indexPath.row])
        }
    }
}
