//
// SearchResultViewController.swift
//
// Copyright © 2021 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

import CelestiaCore

class SearchResultViewController: BaseTableViewController {
    private var resultSections: [SearchResultSection] = []

    private let selected: (String) -> Void

    private let inSidebar: Bool

    init(inSidebar: Bool, selected: @escaping (String) -> Void) {
        self.inSidebar = inSidebar
        self.selected = selected
        super.init(style: inSidebar ? .defaultGrouped : .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension SearchResultViewController {
    func setUp() {
        tableView.register(inSidebar ? UITableViewCell.self : SettingTextCell.self, forCellReuseIdentifier: "Text")
    }
}

extension SearchResultViewController {
    func update(_ results: [SearchResultSection]) {
        resultSections = results
        tableView.reloadData()
    }
}

extension SearchResultViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return resultSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultSections[section].results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = resultSections[indexPath.section].results[indexPath.row]
        if inSidebar {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath)
            if #available(iOS 14.0, *) {
                var configuration = UIListContentConfiguration.sidebarCell()
                configuration.text = result.name
                cell.contentConfiguration = configuration
            } else {
                cell.textLabel?.text = result.name
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = result.name
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return resultSections[section].title
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if #available(iOS 13.0, *) {
        } else if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = UIColor.darkPlainHeaderLabel
            header.backgroundView = UIView()
            header.backgroundView?.backgroundColor = .darkPlainHeaderBackground
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selection = resultSections[indexPath.section].results[indexPath.row]
        selected(selection.name)
    }
}
