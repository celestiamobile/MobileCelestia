//
// AboutViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class AboutViewController: BaseTableViewController {
    private var items: [[TextItem]] = []

    init() {
        super.init(style: .defaultGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        loadContents()
    }

    private func loadContents() {
        var totalItems = [[TextItem]]()

        let shortVersion = Bundle.app.infoDictionary!["CFBundleShortVersionString"] as! String
        let buildNumber = Bundle.app.infoDictionary!["CFBundleVersion"] as! String
        let versionItem = TextItem.short(title: CelestiaString("Version", comment: ""), detail: "\(shortVersion)(\(buildNumber))")

        totalItems.append([versionItem])

        let authorsPath = UserDefaults.defaultDataDirectory.appendingPathComponent("AUTHORS").path
        if let text = try? String(contentsOfFile: authorsPath) {
            totalItems.append([
                TextItem.short(title: CelestiaString("Authors", comment: ""), detail: ""),
                TextItem.long(content: text)
            ])
        }

        let translatorsPath = UserDefaults.defaultDataDirectory.appendingPathComponent("TRANSLATORS").path
        if let text = try? String(contentsOfFile: translatorsPath) {
            totalItems.append([
                TextItem.short(title: CelestiaString("Translators", comment: ""), detail: ""),
                TextItem.long(content: text)
            ])
        }

        totalItems.append([
            TextItem.link(title: CelestiaString("Development", comment: ""), url: URL(string: "https://celestia.mobi/help/development")!),
            TextItem.link(title: CelestiaString("Third Party Dependencies", comment: ""), url: URL(string: "https://celestia.mobi/help/dependencies")!),
            TextItem.link(title: CelestiaString("Privacy Policy and Service Agreement", comment: ""), url: URL(string: "https://celestia.mobi/privacy")!)
        ])

        totalItems.append([
            TextItem.link(title: CelestiaString("Official Website", comment: ""), url: officialWebsiteURL),
            TextItem.link(title: CelestiaString("Support Forum", comment: ""), url: supportForumURL)
        ])

        items = totalItems
        tableView.reloadData()
    }
}

private extension AboutViewController {
    func setup() {
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(MultiLineTextCell.self, forCellReuseIdentifier: "MultiLine")
        title = CelestiaString("About", comment: "")
    }
}

extension AboutViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .short(let title, let detail):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
            cell.title = title
            cell.detail = detail
            cell.selectionStyle = .none
            return cell
        case .long(let content):
            let cell = tableView.dequeueReusableCell(withIdentifier: "MultiLine", for: indexPath) as! MultiLineTextCell
            cell.title = content
            cell.selectionStyle = .none
            return cell
        case .link(let title, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
            cell.title = title
            #if targetEnvironment(macCatalyst)
            cell.titleColor = cell.tintColor
            #else
            cell.titleColor = UIColor.themeLabel
            #endif
            cell.selectionStyle = .default
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .link(_, let url):
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        default:
            break
        }
    }
}
