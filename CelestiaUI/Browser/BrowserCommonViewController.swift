//
// BrowserCommonViewController.swift
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

class BrowserCommonViewController: BaseTableViewController {
    private let item: BrowserItem

    private let selection: (BrowserItem, Bool) -> Void
    private let showAddonCategory: (CategoryInfo) -> Void
    private let categoryInfo: CategoryInfo?

    enum Section {
        case main
        case subsystem
        case children
        case categoryCard
    }

    enum Item: Hashable {
        case item(item: BrowserItem, isMain: Bool)
    }

    class BrowserDataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            if let identifier = sectionIdentifierCompat(for: section), identifier == .subsystem {
                return CelestiaString("Subsystem", comment: "Subsystem of an object (e.g. planetarium system)")
            }
            return nil
        }
    }

    private lazy var dataSource = BrowserDataSource(tableView: tableView) { tableView, indexPath, itemIdentifier in
        switch itemIdentifier {
        case .item(let item, let isMain):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
            cell.title = item.name
            if isMain {
                cell.accessoryType = .none
            } else {
                cell.accessoryType = item.entry != nil && item.children.isEmpty ? .none : .disclosureIndicator
            }
            return cell
        }
    }

    init(item: BrowserItem, selection: @escaping (BrowserItem, Bool) -> Void, showAddonCategory: @escaping (CategoryInfo) -> Void) {
        self.item = item
        self.selection = selection
        self.showAddonCategory = showAddonCategory
        self.categoryInfo = (item as? BrowserPredefinedItem)?.categoryInfo
        super.init(style: .defaultGrouped)
        title = item.alternativeName ?? item.name
        windowTitle = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension BrowserCommonViewController {
    func setUp() {
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(TeachingCardCell.self, forHeaderFooterViewReuseIdentifier: "TeachingCard")

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        if item.entry != nil {
            snapshot.appendSections([.main])
            snapshot.appendItems([.item(item: item, isMain: true)], toSection: .main)
        }

        if !item.children.isEmpty {
            let section: Section = item.entry != nil ? .subsystem : .children
            snapshot.appendSections([section])
            snapshot.appendItems(item.children.map { .item(item: $0, isMain: false) }, toSection: section)
        }

        if categoryInfo != nil {
            snapshot.appendSections([.categoryCard])
        }

        tableView.dataSource = dataSource
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }
}

extension BrowserCommonViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case let .item(item, isMain):
            if isMain {
                tableView.deselectRow(at: indexPath, animated: true)
                selection(item, true)
            } else {
                let isLeaf = item.entry != nil && item.children.isEmpty
                if isLeaf {
                    tableView.deselectRow(at: indexPath, animated: true)
                }
                selection(item, isLeaf)
            }
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let sectionIdentifier = dataSource.sectionIdentifierCompat(for: section), let categoryInfo, sectionIdentifier == .categoryCard else { return nil }

        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TeachingCard") as! TeachingCardCell
        cell.teachingCard.contentConfiguration = TeachingCardContentConfiguration(title: CelestiaString("Enhance Celestia with online add-ons", comment: ""), actionButtonTitle: CelestiaString("Get Add-ons", comment: "Open webpage for downloading add-ons"))
        cell.teachingCard.actionButtonTapped = { [weak self] in
            guard let self else { return }
            self.showAddonCategory(categoryInfo)
        }
        return cell
    }
}

extension UITableViewDiffableDataSource {
    func sectionIdentifierCompat(for index: Int) -> SectionIdentifierType? {
        if #available(iOS 15, *) {
            return sectionIdentifier(for: index)
        } else {
            let sectionIdentifiers = snapshot().sectionIdentifiers
            if sectionIdentifiers.count > index {
                return sectionIdentifiers[index]
            }
            return nil
        }
    }
}
