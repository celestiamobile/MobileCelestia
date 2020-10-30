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
    private var activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    private var refreshButton = UIButton(type: .system)

    private var items: [T] = []
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

    func refresh(success: @escaping ([T]) -> Void, failure: @escaping (Error) -> Void) {}

    @objc private func callRefresh() {
        startRefreshing()
        refresh { [weak self] (items) in
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {   return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = items[indexPath.row].name
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selection(items[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

private extension AsyncListViewController {
    func setup() {
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")

        refreshButton.setTitle(CelestiaString("Refresh", comment: ""), for: .normal)
        refreshButton.setTitleColor(.darkLabel, for: .normal)
        refreshButton.addTarget(self, action: #selector(callRefresh), for: .touchUpInside)
    }
}
