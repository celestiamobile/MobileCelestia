// ObserverModeViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

public class ObserverModeViewController: UICollectionViewController {
    private let executor: AsyncProviderExecutor

    private let supportedCoordinateSystems: [CoordinateSystem] = [
        .universal,
        .ecliptical,
        .bodyFixed,
        .phaseLock,
        .chase
    ]

    private var coordinateSystem: CoordinateSystem = .universal
    private var referenceObjectName = ""
    private var targetObjectName = ""
    private var referenceObject = Selection()
    private var targetObject = Selection()

    private enum Section {
        case single
    }

    private enum Item {
        case coordinateSystem
        case referenceObjectName
        case targetObjectName
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let cellRegistration = UICollectionView.CellRegistration<SelectableListCell, Item> { [unowned self] cell, _, itemIdentifier in
            var configuration = UIListContentConfiguration.celestiaValueCell()
            let text: String
            var secondaryText: String?
            var selectable = true
            let accessories: [UICellAccessory]
            switch itemIdentifier {
            case .coordinateSystem:
                text = CelestiaString("Coordinate System", comment: "Used in Flight Mode")
                selectable = false
                #if targetEnvironment(macCatalyst)
                let button = UIButton(type: .system)
                #else
                let button = UIButton(configuration: .plain())
                #endif
                button.showsMenuAsPrimaryAction = true
                button.changesSelectionAsPrimaryAction = true
                button.menu = UIMenu(children: self.supportedCoordinateSystems.map({ coordinateSystem in
                    UIAction(title: coordinateSystem.name, state: self.coordinateSystem == coordinateSystem ? .on : .off) { [weak self] _ in
                        guard let self else { return }
                        self.coordinateSystem = coordinateSystem
                        self.reload()
                    }
                }))
                accessories = [
                    .customView(configuration: UICellAccessory.CustomViewConfiguration(customView: button, placement: .trailing(displayed: .always))),
                ]
            case .referenceObjectName:
                text = CelestiaString("Reference Object", comment: "Used in Flight Mode")
                secondaryText = self.referenceObjectName
                accessories = [.disclosureIndicator()]
            case .targetObjectName:
                text = CelestiaString("Target Object", comment: "Used in Flight Mode")
                secondaryText = self.targetObjectName
                accessories = [.disclosureIndicator()]
            }
            configuration.text = text
            configuration.secondaryText = secondaryText
            cell.contentConfiguration = configuration
            cell.selectable = selectable
            cell.accessories = accessories
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        let footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) { supplementaryView, elementKind, indexPath in
            supplementaryView.contentConfiguration = LinkTextConfiguration(
                info: LinkTextConfiguration.LinkInfo(text: CelestiaString("Flight mode decides how you move around in Celestia. Learn more…", comment: ""), links: [LinkTextConfiguration.Link(text: CelestiaString("Learn more…", comment: "Text for the link in Flight mode decides how you move around in Celestia. Learn more…"), link: "https://celestia.mobi/help/flight-mode?lang=\(AppCore.language)")]),
                directionalLayoutMargins: NSDirectionalEdgeInsets(top: GlobalConstants.listItemMediumMarginVertical, leading: GlobalConstants.listItemMediumMarginHorizontal, bottom: GlobalConstants.listItemMediumMarginVertical, trailing: GlobalConstants.listItemMediumMarginHorizontal)
            )
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self else { return nil }
            let section = self.dataSource.sectionIdentifier(for: indexPath.section)
            if kind == UICollectionView.elementKindSectionFooter {
                return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration, for: indexPath)
            }
            return nil
        }

        return dataSource
    }()

    public init(executor: AsyncProviderExecutor) {
        self.executor = executor
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
            configuration.footerMode = .supplementary
            return .list(using: configuration, layoutEnvironment: environment)
        })
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    @objc private func applyObserverMode() {
        let system = coordinateSystem
        let ref = referenceObject
        let target = targetObject

        Task {
            await executor.run { appCore in
                appCore.simulation.activeObserver.setFrame(coordinate: system, target: target, reference: ref)
            }
        }
    }

    private func reload() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.single])
        switch coordinateSystem {
        case .universal:
            snapshot.appendItems([.coordinateSystem], toSection: .single)
        case .ecliptical, .bodyFixed, .chase:
            snapshot.appendItems([.coordinateSystem, .referenceObjectName], toSection: .single)
        case .phaseLock:
            snapshot.appendItems([.coordinateSystem, .referenceObjectName, .targetObjectName], toSection: .single)
        default:
            snapshot.appendItems([.coordinateSystem], toSection: .single)
        }
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

private extension ObserverModeViewController {
    func setUp() {
        navigationItem.backButtonTitle = ""
        title = CelestiaString("Flight Mode", comment: "")
        windowTitle = title
        #if !os(visionOS)
        collectionView.keyboardDismissMode = .interactive
        #endif

        collectionView.dataSource = dataSource

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CelestiaString("OK", comment: ""), style: .plain, target: self, action: #selector(applyObserverMode))

        reload()
    }
}

extension ObserverModeViewController {
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .coordinateSystem:
            break
        case .referenceObjectName:
            let searchController = SearchViewController(executor: executor) { [weak self] _, displayName, object in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
                self.referenceObjectName = displayName
                self.referenceObject = object
                self.reload()
            }
            navigationController?.pushViewController(searchController, animated: true)
        case .targetObjectName:
            let searchController = SearchViewController(executor: executor) { [weak self] _, displayName, object in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
                self.targetObjectName = displayName
                self.targetObject = object
                self.reload()
            }
            navigationController?.pushViewController(searchController, animated: true)
        }
    }
}

private extension CoordinateSystem {
    var name: String {
        switch self {
        case .universal:
            return CelestiaString("Free Flight", comment: "Flight mode, coordinate system")
        case .ecliptical:
            return CelestiaString("Follow", comment: "")
        case .bodyFixed:
            return CelestiaString("Sync Orbit", comment: "")
        case .phaseLock:
            return CelestiaString("Phase Lock", comment: "Flight mode, coordinate system")
        case .chase:
            return CelestiaString("Chase", comment: "")
        default:
            return ""
        }
    }
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: ObserverModeViewController.self).bundleIdentifier!
    fileprivate static let confirmObserverMode = NSToolbarItem.Identifier.init("\(prefix).observermode.confirm")
}

extension ObserverModeViewController: ToolbarAwareViewController {
    public func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier] {
        return [.confirmObserverMode]
    }

    public func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        if itemIdentifier == .confirmObserverMode {
            return NSToolbarItem(itemIdentifier: itemIdentifier, buttonTitle: CelestiaString("OK", comment: ""), target: self, action: #selector(applyObserverMode))
        }
        return nil
    }
}
#endif
