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
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .item(let item, let isMain):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Text", for: indexPath) as! UICollectionViewListCell
                var configuration = UIListContentConfiguration.celestiaCell()
                configuration.text = item.name
                cell.contentConfiguration = configuration
                if isMain {
                    cell.accessories = []
                } else {
                    cell.accessories = item.entry != nil && item.children.isEmpty ? [] : [.disclosureIndicator()]
                }
                return cell
            }
        }
        dataSource.supplementaryViewProvider = { [weak self, weak dataSource] collectionView, kind, indexPath in
            if kind == UICollectionView.elementKindSectionHeader {
                let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! UICollectionViewListCell
                var configuration = UIListContentConfiguration.groupedHeader()
                if let dataSource, let identifier = dataSource.sectionIdentifierCompat(for: indexPath.section), identifier == .subsystem {
                    configuration.text = CelestiaString("Subsystem", comment: "Subsystem of an object (e.g. planetarium system)")
                }
                cell.contentConfiguration = configuration
                return cell
            }
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath) as! UICollectionViewListCell
            var configuration: UIContentConfiguration
            if let self, let dataSource, let sectionIdentifier = dataSource.sectionIdentifierCompat(for: indexPath.section), let categoryInfo = self.categoryInfo, sectionIdentifier == .categoryCard {
                configuration = TeachingCardContentConfiguration(title: CelestiaString("Enhance Celestia with online add-ons", comment: ""), actionButtonTitle: CelestiaString("Get Add-ons", comment: "Open webpage for downloading add-ons")) { [weak self] in
                    guard let self else { return }
                    self.showAddonCategory(categoryInfo)
                }
            } else {
                configuration = UIListContentConfiguration.groupedFooter()
            }
            cell.contentConfiguration = configuration
            return cell
        }
        return dataSource
    }()

    init(item: BrowserItem, selection: @escaping (BrowserItem, Bool) -> Void, showAddonCategory: @escaping (CategoryInfo) -> Void) {
        self.item = item
        self.selection = selection
        self.showAddonCategory = showAddonCategory
        self.categoryInfo = (item as? BrowserPredefinedItem)?.categoryInfo
        var config = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
        config.headerMode = .supplementary
        config.footerMode = .supplementary
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: config))
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
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "Text")
        collectionView.register(UICollectionViewListCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.register(UICollectionViewListCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer")

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

        collectionView.dataSource = dataSource
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
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
        }
    }
}

extension UICollectionViewDiffableDataSource {
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
