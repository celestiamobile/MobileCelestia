// EventFinderResultViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

class EventFinderResultViewController: UICollectionViewController {
    private let eventHandler: ((Eclipse) -> Void)
    private let events: [Eclipse]

    private enum Section {
        case single
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Eclipse> = {
        let displayDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }()
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Eclipse> { cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = "\(itemIdentifier.occulter.name) -> \(itemIdentifier.receiver.name)"
            contentConfiguration.secondaryText = displayDateFormatter.string(from: itemIdentifier.startTime)
            contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: GlobalConstants.listItemMediumMarginVertical, leading: GlobalConstants.listItemMediumMarginHorizontal, bottom: GlobalConstants.listItemMediumMarginVertical, trailing: GlobalConstants.listItemMediumMarginHorizontal)
            cell.contentConfiguration = contentConfiguration
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, Eclipse>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        return dataSource
    }()

    init(results: [Eclipse], eventHandler: @escaping ((Eclipse) -> Void)) {
        self.eventHandler = eventHandler
        self.events = results
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .defaultGrouped)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension EventFinderResultViewController {
    func setUp() {
        title = CelestiaString("Eclipse Finder", comment: "")
        windowTitle = title

        collectionView.dataSource = dataSource

        var snapshot = NSDiffableDataSourceSnapshot<Section, Eclipse>()
        snapshot.appendSections([.single])
        snapshot.appendItems(events, toSection: .single)
        dataSource.applySnapshotUsingReloadData(snapshot)

        if events.isEmpty {
            if #available(iOS 17, visionOS 1, *) {
                var empty = UIContentUnavailableConfiguration.empty()
                empty.text = CelestiaString("No eclipse is found for the given object in the time range", comment: "")
                contentUnavailableConfiguration = empty
            } else {
                let view = EmptyHintView()
                view.title = CelestiaString("No eclipse is found for the given object in the time range", comment: "")
                collectionView.backgroundView = view
            }
        }
    }
}

extension EventFinderResultViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let eclipse = dataSource.itemIdentifier(for: indexPath) else { return }
        eventHandler(eclipse)
    }
}

