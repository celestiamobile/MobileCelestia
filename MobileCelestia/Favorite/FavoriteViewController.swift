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
    case bookmark    = 0
    case script      = 1
    case destination = 2
}

private extension FavoriteItemType {
    var description: String {
        switch self {
        case .bookmark:
            return CelestiaString("Bookmarks", comment: "")
        case .script:
            return CelestiaString("Scripts", comment: "")
        case .destination:
            return CelestiaString("Destinations", comment: "")
        }
    }
}

class FavoriteViewController: BaseTableViewController {
    private let selected: (FavoriteItemType) -> Void
    private var currentSelection: FavoriteItemType?

    init(currentSelection: FavoriteItemType?, selected: @escaping (FavoriteItemType) -> Void) {
        self.currentSelection = currentSelection
        self.selected = selected
        super.init(style: .defaultGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let selection = currentSelection {
            currentSelection = nil
            tableView.selectRow(at: IndexPath(row: selection.rawValue, section: 0), animated: false, scrollPosition: .none)
        }
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
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = FavoriteItemType(rawValue: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = type?.description
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected(FavoriteItemType(rawValue: indexPath.row)!)
    }
}
