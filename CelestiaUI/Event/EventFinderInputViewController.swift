// EventFinderInputViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

class EventFinderInputViewController: UICollectionViewController {
    private enum Section {
        case time
        case object
    }

    private enum Item {
        case startTime
        case endTime
        case object
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let displayDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }()
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            let text: String
            var secondaryText: String?
            switch itemIdentifier {
            case .startTime:
                text = CelestiaString("Start Time", comment: "In eclipse finder, range of time to find eclipse in")
                if let self {
                    secondaryText = displayDateFormatter.string(from: self.startTime)
                }
            case .endTime:
                text = CelestiaString("End Time", comment: "In eclipse finder, range of time to find eclipse in")
                if let self {
                    secondaryText = displayDateFormatter.string(from: self.endTime)
                }
            case .object:
                text = CelestiaString("Object", comment: "In eclipse finder, object to find eclipse with, or in go to")
                secondaryText = self?.objectName
            }
            contentConfiguration.text = text
            contentConfiguration.secondaryText = secondaryText
            contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: GlobalConstants.listItemMediumMarginVertical, leading: GlobalConstants.listItemMediumMarginHorizontal, bottom: GlobalConstants.listItemMediumMarginVertical, trailing: GlobalConstants.listItemMediumMarginHorizontal)
            cell.contentConfiguration = contentConfiguration
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        return dataSource
    }()

    private let selectableObjects: [(displayName: String, objectPath: String)] = [(LocalizedString("Earth", "celestia-data"), "Sol/Earth"), (LocalizedString("Jupiter", "celestia-data"), "Sol/Jupiter")]

    private let defaultSearchingInterval: TimeInterval = 365 * 24 * 60 * 60
    private lazy var startTime = endTime.addingTimeInterval(-defaultSearchingInterval)
    private lazy var endTime = Date()
    private var objectName = LocalizedString("Earth", "celestia-data")
    private var objectPath = "Sol/Earth"

    private let executor: AsyncProviderExecutor

    private let resultHandler: (([Eclipse]) -> Void)
    private let textInputHandler: (_ viewController: UIViewController, _ title: String) async -> String?
    private let dateInputHandler: (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?

    init(
        executor: AsyncProviderExecutor,
        resultHandler: @escaping (([Eclipse]) -> Void),
        textInputHandler: @escaping (_ viewController: UIViewController, _ title: String) async -> String?,
        dateInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?
    ) {
        self.executor = executor
        self.resultHandler = resultHandler
        self.textInputHandler = textInputHandler
        self.dateInputHandler = dateInputHandler

        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .defaultGrouped)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension EventFinderInputViewController {
    func setup() {
        title = CelestiaString("Eclipse Finder", comment: "")
        windowTitle = title

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CelestiaString("Find", comment: "Find (eclipses)"), style: .plain, target: self, action: #selector(findEclipse))

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.time, .object])
        snapshot.appendItems([.startTime, .endTime], toSection: .time)
        snapshot.appendItems([.object], toSection: .object)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }

    @objc private func findEclipse() {
        Task {
            let objectPath = self.objectPath
            guard let body = await executor.get({ core in return core.simulation.findObject(from: objectPath).body }) else {
                showError(CelestiaString("Object not found", comment: ""))
                return
            }

            let finder = EclipseFinder(body: body)
            let alert = showLoading(CelestiaString("Calculating…", comment: "Calculating for eclipses")) {
                finder.abort()
            }

            let results = await finder.search(kind: [.lunar, .solar], from: self.startTime, to: self.endTime)
            alert.dismiss(animated: true) {
                self.resultHandler(results)
            }
        }
    }
}

extension EventFinderInputViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .startTime, .endTime:
            let preferredFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMddHHmmss", options: 0, locale: Locale.current) ?? "yyyy/MM/dd HH:mm:ss"
            Task {
                let title = String.localizedStringWithFormat(CelestiaString("Please enter the time in \"%@\" format.", comment: ""), preferredFormat)
                guard let date = await self.dateInputHandler(self, title, preferredFormat) else {
                    self.showError(CelestiaString("Unrecognized time string.", comment: "String not in correct format"))
                    return
                }
                if item == .startTime {
                    self.startTime = date
                } else {
                    self.endTime = date
                }
    
                var snapshot = dataSource.snapshot()
                snapshot.reloadItems([item])
                await self.dataSource.apply(snapshot)
            }
        case .object:
            if let cell = collectionView.cellForItem(at: indexPath) {
                showSelection(CelestiaString("Please choose an object.", comment: "In eclipse finder, choose an object to find eclipse wth"),
                              options: selectableObjects.map { $0.displayName } + [CelestiaString("Other", comment: "Other location labels; Android/iOS, Other objects to choose from in Eclipse Finder")],
                              source: .view(view: cell, sourceRect: nil)) { [weak self] index in
                    guard let self = self, let index = index else { return }
                    if index >= self.selectableObjects.count {
                        // User choose other, show text input for the object name
                        Task {
                            if let text = await self.textInputHandler(self, CelestiaString("Please enter an object name.", comment: "In Go to; Android/iOS, Enter the name of an object in Eclipse Finder")) {
                                self.objectName = text
                                self.objectPath = text

                                var snapshot = dataSource.snapshot()
                                snapshot.reloadItems([item])
                                await self.dataSource.apply(snapshot)
                            }
                        }
                        return
                    }
                    self.objectName = self.selectableObjects[index].displayName
                    self.objectPath = self.selectableObjects[index].objectPath

                    var snapshot = dataSource.snapshot()
                    snapshot.reloadItems([item])
                    self.dataSource.apply(snapshot)
                }
            }
        }
    }
}

extension Body: @unchecked @retroactive Sendable {}
extension EclipseFinder: @unchecked @retroactive Sendable {}

extension EclipseFinder {
    func search(kind: EclipseKind, from: Date, to: Date) async -> [Eclipse] {
        return await Task.detached(priority: .background) {
            self.search(kind: kind, from: from, to: to)
        }.value
    }
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: GoToInputViewController.self).bundleIdentifier!
    fileprivate static let calculate = NSToolbarItem.Identifier.init("\(prefix).calculate")
}

extension EventFinderInputViewController: ToolbarAwareViewController {
    func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier] {
        return [.calculate]
    }

    func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        if itemIdentifier == .calculate {
            return NSToolbarItem(itemIdentifier: itemIdentifier, buttonTitle: CelestiaString("Find", comment: "Find (eclipses)"), target: self, action: #selector(findEclipse))
        }
        return nil
    }
}
#endif
