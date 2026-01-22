// FavoriteViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

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

class FavoriteViewController: UICollectionViewController {
    private let selected: @MainActor (FavoriteItemType) async -> Void
    private var currentSelection: FavoriteItemType?

    private enum Section {
        case single
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, FavoriteItemType> = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, FavoriteItemType> { cell, indexPath, item in
            #if targetEnvironment(macCatalyst)
            var configuration = UIListContentConfiguration.sidebarCell()
            #else
            cell.accessories = [.disclosureIndicator()]
            var configuration = UIListContentConfiguration.celestiaCell()
            #endif
            configuration.text = item.description
            cell.contentConfiguration = configuration
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, FavoriteItemType>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        return dataSource
    }()

    init(currentSelection: FavoriteItemType?, selected: @MainActor @escaping (FavoriteItemType) async -> Void) {
        self.currentSelection = currentSelection
        self.selected = selected
        #if targetEnvironment(macCatalyst)
        let configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
        #else
        let configuration = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
        #endif
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: configuration))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        if let selection = currentSelection {
            currentSelection = nil
            if let indexPath = dataSource.indexPath(for: selection) {
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                Task {
                    await selected(selection)
                }
            }
        }
    }
}

private extension FavoriteViewController {
    func setup() {
        title = CelestiaString("Favorites", comment: "Favorites (currently bookmarks and scripts)")
        windowTitle = title

        collectionView.dataSource = dataSource

        var snapshot = NSDiffableDataSourceSnapshot<Section, FavoriteItemType>()
        snapshot.appendSections([.single])
        snapshot.appendItems([.bookmark, .script, .destination], toSection: .single)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

extension FavoriteViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedType = dataSource.itemIdentifier(for: indexPath) else { return }
        Task {
            await selected(selectedType)
        }
    }
}
