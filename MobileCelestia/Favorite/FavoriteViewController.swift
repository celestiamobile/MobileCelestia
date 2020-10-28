//
// FavoriteViewController.swift
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

enum FavoriteItemType: Int {
    case bookmark   = 0
    case script     = 1
}

private extension FavoriteItemType {
    var description: String {
        switch self {
        case .bookmark:
            return CelestiaString("Bookmarks", comment: "")
        case .script:
            return CelestiaString("Scripts", comment: "")
        }
    }
}

class FavoriteViewController: BaseTableViewController {
    private let selected: (FavoriteItemType) -> Void

    init(selected: @escaping (FavoriteItemType) -> Void) {
        self.selected = selected
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension FavoriteViewController {
    func setup() {
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        title = CelestiaString("Favorites", comment: "")
    }
}

extension FavoriteViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = FavoriteItemType(rawValue: indexPath.row)?.description
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selected(FavoriteItemType(rawValue: indexPath.row)!)
    }
}
