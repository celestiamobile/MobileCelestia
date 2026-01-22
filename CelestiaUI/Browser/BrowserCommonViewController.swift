// BrowserCommonViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

class BrowserCommonViewController: UICollectionViewController {
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
        case categoryCard
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [unowned self] cell, _, itemIdentifier in
            var configuration: any UIContentConfiguration
            let accessories: [UICellAccessory]
            switch itemIdentifier {
            case let .item(item, isMain):
                var cellConfiguration = UIListContentConfiguration.celestiaCell()
                cellConfiguration.text = item.name
                configuration = cellConfiguration
                if isMain {
                    accessories = []
                } else {
                    accessories = item.entry != nil && item.children.isEmpty ? [] : [.disclosureIndicator()]
                }
            case .categoryCard:
                configuration = TeachingCardContentConfiguration(title: CelestiaString("Enhance Celestia with online add-ons", comment: ""), directionalLayoutMargins: NSDirectionalEdgeInsets(top: GlobalConstants.listItemMediumMarginVertical, leading: GlobalConstants.listItemMediumMarginHorizontal, bottom: GlobalConstants.listItemMediumMarginVertical, trailing: GlobalConstants.listItemMediumMarginHorizontal), actionButtonTitle: CelestiaString("Get Add-ons", comment: "Open webpage for downloading add-ons"), actionHandler: { [weak self] in
                    guard let self, let categoryInfo = self.categoryInfo else { return }
                    self.showAddonCategory(categoryInfo)
                })
                accessories = []
            }
            cell.contentConfiguration = configuration
            cell.accessories = accessories
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
            var contentConfiguration = UIListContentConfiguration.groupedFooter()
            contentConfiguration.text = CelestiaString("Subsystem", comment: "Subsystem of an object (e.g. planetarium system)")
            supplementaryView.contentConfiguration = contentConfiguration
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self else { return nil }
            let section = self.dataSource.sectionIdentifier(for: indexPath.section)
            if section == .subsystem, kind == UICollectionView.elementKindSectionHeader {
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            }
            return nil
        }

        return dataSource
    }()

    init(item: BrowserItem, selection: @escaping (BrowserItem, Bool) -> Void, showAddonCategory: @escaping (CategoryInfo) -> Void) {
        self.item = item
        self.selection = selection
        self.showAddonCategory = showAddonCategory
        let categoryInfo = (item as? BrowserPredefinedItem)?.categoryInfo
        self.categoryInfo = categoryInfo

        super.init(collectionViewLayout: UICollectionViewFlowLayout())

        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { [unowned self] sectionIndex, environment in
            var config = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
            if let section = self.dataSource.sectionIdentifier(for: sectionIndex) {
                if section == .subsystem {
                    config.headerMode = .supplementary
                }
            }
            return .list(using: config, layoutEnvironment: environment)
        })

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
            snapshot.appendItems([.categoryCard], toSection: .categoryCard)
        }
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

extension BrowserCommonViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case let .item(item, isMain):
            if isMain {
                collectionView.deselectItem(at: indexPath, animated: true)
                selection(item, true)
            } else {
                let isLeaf = item.entry != nil && item.children.isEmpty
                if isLeaf {
                    collectionView.deselectItem(at: indexPath, animated: true)
                }
                selection(item, isLeaf)
            }
        case .categoryCard:
            break
        }
    }
}
