//
// AboutViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaFoundation
import UIKit

public final class AboutViewController: BaseTableViewController {
    private let officialWebsiteURL = URL(string: "https://celestia.mobi")!
    private let aboutCelestiaURL = URL(string: "https://celestia.mobi/about")!

    private var items: [[TextItem]] = []

    private let bundle: Bundle
    private let defaultDirectoryURL: URL

    public init(bundle: Bundle, defaultDirectoryURL: URL) {
        self.bundle = bundle
        self.defaultDirectoryURL = defaultDirectoryURL
        super.init(style: .defaultGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()

        loadContents()
    }

    private func loadContents() {
        var totalItems = [[TextItem]]()

        let versionItem = TextItem.short(title: CelestiaString("Version", comment: ""), detail: "\(bundle.shortVersion)(\(bundle.build))")

        totalItems.append([versionItem])

        let authorsPath = defaultDirectoryURL.appendingPathComponent("AUTHORS").path
        if let text = try? String(contentsOfFile: authorsPath) {
            totalItems.append([
                TextItem.short(title: CelestiaString("Authors", comment: ""), detail: ""),
                TextItem.long(content: text)
            ])
        }

        let translatorsPath = defaultDirectoryURL.appendingPathComponent("TRANSLATORS").path
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
            TextItem.link(title: CelestiaString("About Celestia", comment: ""), url: aboutCelestiaURL),
        ])

        items = totalItems
        tableView.reloadData()
    }
}

private extension AboutViewController {
    func setUp() {
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(MultiLineTextCell.self, forCellReuseIdentifier: "MultiLine")
        title = CelestiaString("About", comment: "")
    }
}

extension AboutViewController {
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .short(let title, let detail):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
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

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
