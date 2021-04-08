//
// ResourceCategoryViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

import CelestiaCore

class ResourceCategoryListViewController: AsyncListViewController {
    private var categories: [ResourceCategory] = []

    override func loadView() {
        super.loadView()
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refresh()
    }

    override func refresh() {
        let requestURL = "https://astroweather.cn/celestia/resource/categories"
        let locale = LocalizedString("LANGUAGE", "celestia")

        startRefreshing()
        _ = RequestHandler.get(url: requestURL, params: ["lang" : locale], success: { [weak self] (result: [ResourceCategory]) in
            self?.categories = result
            self?.tableView.reloadData()
            self?.stopRefreshing(success: true)
            self?.showError("Failed to get plugin categories.")
        }, fail: { [weak self] error in
            self?.stopRefreshing(success: false)
        })
    }
}

private extension ResourceCategoryListViewController {
    func setup() {
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        tableView.dataSource = self
        tableView.delegate = self

        // TODO: Localization
        title = "Categories"
    }
}

extension ResourceCategoryListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {        return categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = categories[indexPath.row].name
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
