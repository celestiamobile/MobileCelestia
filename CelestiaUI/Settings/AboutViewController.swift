// AboutViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
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
                TextItem.short(title: CelestiaString("Authors", comment: "Authors for Celestia"), detail: ""),
                TextItem.long(content: text)
            ])
        }

        let translatorsPath = defaultDirectoryURL.appendingPathComponent("TRANSLATORS").path
        if let text = try? String(contentsOfFile: translatorsPath) {
            totalItems.append([
                TextItem.short(title: CelestiaString("Translators", comment: "Translators for Celestia"), detail: ""),
                TextItem.long(content: text)
            ])
        }

        totalItems.append([
            TextItem.link(title: CelestiaString("Development", comment: "URL for Development wiki"), url: URL(string: "https://celestia.mobi/help/development")!, localizable: false),
            TextItem.link(title: CelestiaString("Third Party Dependencies", comment: "URL for Third Party Dependencies wiki"), url: URL(string: "https://celestia.mobi/help/dependencies")!, localizable: true),
            TextItem.link(title: CelestiaString("Privacy Policy and Service Agreement", comment: "Privacy Policy and Service Agreement"), url: URL(string: "https://celestia.mobi/privacy")!, localizable: true)
        ])

        totalItems.append([
            TextItem.link(title: CelestiaString("Official Website", comment: ""), url: officialWebsiteURL, localizable: true),
            TextItem.link(title: CelestiaString("About Celestia", comment: "System menu item"), url: aboutCelestiaURL, localizable: true),
        ])

        items = totalItems
        tableView.reloadData()
    }
}

private extension AboutViewController {
    func setUp() {
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(MultiLineTextCell.self, forCellReuseIdentifier: "MultiLine")
        #if !targetEnvironment(macCatalyst)
        tableView.register(ICPCFooter.self, forHeaderFooterViewReuseIdentifier: "ICPC")
        #endif
        title = CelestiaString("About", comment: "About Celstia...")
        windowTitle = title
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
            cell.titleColor = .label
            cell.detail = detail
            cell.selectionStyle = .none
            return cell
        case .long(let content):
            let cell = tableView.dequeueReusableCell(withIdentifier: "MultiLine", for: indexPath) as! MultiLineTextCell
            cell.title = content
            cell.selectionStyle = .none
            return cell
        case .link(let title, _, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
            cell.title = title
            cell.detail = nil
            cell.titleColor = cell.tintColor
            cell.selectionStyle = .default
            return cell
        case .action:
            fatalError()
        }
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .link(_, let url, let localizable):
            let urlToOpen: URL
            if localizable {
                if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    var queryItems = components.queryItems ?? []
                    queryItems.append(URLQueryItem(name: "lang", value: AppCore.language))
                    components.queryItems = queryItems
                    urlToOpen = components.url ?? url
                } else {
                    urlToOpen = url
                }
            } else {
                urlToOpen = url
            }
            UIApplication.shared.open(urlToOpen, options: [:], completionHandler: nil)
        default:
            break
        }
    }

    #if !targetEnvironment(macCatalyst)
    public override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let showFooter: Bool
        if section == items.count - 1 {
            if #available(iOS 16, visionOS 1, *) {
                showFooter = Locale.current.region == .chinaMainland
            } else {
                showFooter = Locale.current.regionCode == "CN"
            }
        } else {
            showFooter = false
        }
        return showFooter ? tableView.dequeueReusableHeaderFooterView(withIdentifier: "ICPC") : nil
    }
    #endif
}
