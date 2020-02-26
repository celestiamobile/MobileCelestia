//
//  AboutViewController.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/25.
//  Copyright © 2020 李林峰. All rights reserved.
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

        if let authorsPath = Bundle.main.path(forResource: "AUTHORS", ofType: nil), let text = try? String(contentsOfFile: authorsPath) {
            totalItems.append([
                TextItem.short(title: CelestiaString("Authors", comment: ""), detail: ""),
                TextItem.long(content: text)
            ])
        }

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
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .short(_, _):
            return 44
        case .long(_):
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
