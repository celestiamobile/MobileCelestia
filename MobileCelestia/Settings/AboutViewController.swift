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

class AboutViewController: UIViewController {

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private var items: [[TextItem]] = []

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground

        title = CelestiaString("About", comment: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        loadContents()
    }

    private func loadContents() {
        var totalItems = [[TextItem]]()

        let shortVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let buildNumber = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        let versionItem = TextItem.short(title: CelestiaString("Version", comment: ""), detail: "\(shortVersion)(\(buildNumber))")

        totalItems.append([versionItem])

        let authorsPath = defaultDataDirectory.appendingPathComponent("AUTHORS").path
        if let text = try? String(contentsOfFile: authorsPath) {
            totalItems.append([
                TextItem.short(title: CelestiaString("Authors", comment: ""), detail: ""),
                TextItem.long(content: text)
            ])
        }

        let translatorsPath = defaultDataDirectory.appendingPathComponent("TRANSLATORS").path
        if let text = try? String(contentsOfFile: translatorsPath) {
            totalItems.append([
                TextItem.short(title: CelestiaString("Translators", comment: ""), detail: ""),
                TextItem.long(content: text)
            ])
        }

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
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.separatorColor = .darkSeparator

        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(MultiLineTextCell.self, forCellReuseIdentifier: "MultiLine")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension AboutViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            cell.titleColor = UIColor.themeLabel
            cell.selectionStyle = .default
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .short(_, _):
            fallthrough
        case .link(_, _):
            return 44
        case .long(_):
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .link(_, let url):
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
