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

import CelestiaCore
import UIKit

enum FavoriteItemType: Int {
    case bookmark    = 0
    case script      = 1
    case destination = 2
}

private extension FavoriteItemType {
    var description: String {
        switch self {
        case .bookmark:
            return CelestiaString("Bookmarks", comment: "URL bookmarks")
        case .script:
            return CelestiaString("Scripts", comment: "")
        case .destination:
            return CelestiaString("Destinations", comment: "A list of destinations in guide")
        }
    }
}

class FavoriteViewController: BaseTableViewController {
    private let selected: @MainActor (FavoriteItemType) async -> Void
    private var currentSelection: FavoriteItemType?

    init(currentSelection: FavoriteItemType?, selected: @MainActor @escaping (FavoriteItemType) async -> Void) {
        self.currentSelection = currentSelection
        self.selected = selected
        #if targetEnvironment(macCatalyst)
        super.init(style: .grouped)
        #else
        super.init(style: .defaultGrouped)
        #endif
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
            Task {
                await selected(selection)
            }
        }
    }
}

private extension FavoriteViewController {
    func setup() {
        #if targetEnvironment(macCatalyst)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Text")
        #else
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        #endif
        title = CelestiaString("Favorites", comment: "Favorites (currently bookmarks and scripts)")
    }
}

extension FavoriteViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = FavoriteItemType(rawValue: indexPath.row)
        #if targetEnvironment(macCatalyst)
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath)
        var configuration = UIListContentConfiguration.sidebarCell()
        configuration.text = type?.description
        cell.contentConfiguration = configuration
        #else
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
        cell.title = type?.description
        cell.accessoryType = .disclosureIndicator
        #endif
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedType = FavoriteItemType(rawValue: indexPath.row) else { return }
        Task {
            await selected(selectedType)
        }
    }
}
