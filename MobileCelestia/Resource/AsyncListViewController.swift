//
// AsyncListViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

protocol AsyncListItem {
    var name: String { get }
}

class AsyncListViewController<T: AsyncListItem>: BaseTableViewController {
    var showDisclosureIndicator: Bool { return true }
    var useStandardUITableViewCell: Bool { return false }

    private lazy var activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13, *) {
            return UIActivityIndicatorView(style: .large)
        } else {
            return UIActivityIndicatorView(style: .whiteLarge)
        }
    }()
    private lazy var refreshButton = UIButton(type: .system)

    private var items: [[T]] = []
    private var selection: (T) -> Void

    init(selection: @escaping (T) -> Void) {
        self.selection = selection
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        callRefresh()
    }

    func refresh(success: @escaping ([[T]]) -> Void, failure: @escaping (Error) -> Void) {}

    @objc private func callRefresh() {
        startRefreshing()
        refresh { [weak self] items in
            self?.items = items
            self?.tableView.reloadData()
            self?.stopRefreshing(success: true)
        } failure: { [weak self] error in
            self?.stopRefreshing(success: false)
            self?.showError(error.localizedDescription)
        }
    }

    func startRefreshing() {
        tableView.backgroundView = activityIndicator
        activityIndicator.startAnimating()
    }

    func stopRefreshing(success: Bool) {
        tableView.backgroundView = success ? nil : refreshButton
        activityIndicator.stopAnimating()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {   return items[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section][indexPath.row]
        if useStandardUITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath)
            if #available(iOS 14, *) {
                var configuration = cell.defaultContentConfiguration()
                configuration.text = item.name
                cell.contentConfiguration = configuration
            } else {
                cell.textLabel?.text = item.name
            }
            cell.accessoryType = showDisclosureIndicator ? .disclosureIndicator : .none
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = item.name
        cell.accessoryType = showDisclosureIndicator ? .disclosureIndicator : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selection(items[indexPath.section][indexPath.row])
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return useStandardUITableViewCell ? UITableView.automaticDimension : 44
    }
}

private extension AsyncListViewController {
    func setup() {
        if useStandardUITableViewCell {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Text")
        } else {
            tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        }

        refreshButton.setTitle(CelestiaString("Refresh", comment: ""), for: .normal)
        refreshButton.setTitleColor(.darkLabel, for: .normal)
        refreshButton.addTarget(self, action: #selector(callRefresh), for: .touchUpInside)
    }
}
