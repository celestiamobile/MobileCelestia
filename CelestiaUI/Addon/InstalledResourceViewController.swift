// InstalledResourceViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

class InstalledResourceViewController: UICollectionViewController {
    private let resourceManager: ResourceManager
    private let getAddonsHandler: () -> Void
    #if !os(visionOS)
    private let showUpdatesHandler: () -> Void
    #endif
    private let selection: (ResourceItem) -> Void

    private var isLoading = false

    private enum Section {
        case single
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, ResourceItem> = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ResourceItem> { cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.celestiaCell()
            contentConfiguration.text = itemIdentifier.name
            cell.contentConfiguration = contentConfiguration
            cell.accessories = [.disclosureIndicator()]
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, ResourceItem>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        return dataSource
    }()

    private lazy var items: [ResourceItem] = []

    private lazy var emptyView: UIView = {
        let view = EmptyHintView()
        view.title = CelestiaString("Enhance Celestia with online add-ons", comment: "")
        view.actionText = CelestiaString("Get Add-ons", comment: "Open webpage for downloading add-ons")
        view.action = { [weak self] in
            guard let self else { return }
            self.getAddonsHandler()
        }
        return view
    }()

    #if os(visionOS)
    init(resourceManager: ResourceManager, selection: @escaping (ResourceItem) -> Void, getAddonsHandler: @escaping () -> Void) {
        self.resourceManager = resourceManager
        self.getAddonsHandler = getAddonsHandler
        self.selection = selection
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .defaultGrouped)))
    }
    #else
    init(resourceManager: ResourceManager, selection: @escaping (ResourceItem) -> Void, getAddonsHandler: @escaping () -> Void, showUpdatesHandler: @escaping () -> Void) {
        self.resourceManager = resourceManager
        self.getAddonsHandler = getAddonsHandler
        self.showUpdatesHandler = showUpdatesHandler
        self.selection = selection
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .defaultGrouped)))
    }
    #endif
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = CelestiaString("Installed", comment: "Title for the list of installed add-ons")
        windowTitle = title

        collectionView.dataSource = dataSource

        #if !os(visionOS)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CelestiaString("Updates", comment: "View the list of add-ons that have pending updates."), style: .plain, target: self, action: #selector(showUpdates))
        #endif

        NotificationCenter.default.addObserver(self, selector: #selector(unzipSuccess(_:)), name: ResourceManager.unzipSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uninstallSuccess(_:)), name: ResourceManager.uninstallSuccess, object: nil)

        reload()
    }

    @available(iOS 17.0, visionOS 1, *)
    override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
        if items.isEmpty {
            if isLoading {
                contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
            } else {
                var config = UIContentUnavailableConfiguration.empty()
                config.text = CelestiaString("Enhance Celestia with online add-ons", comment: "")
                #if !targetEnvironment(macCatalyst)
                let button = UIButton.Configuration.filled()
                config.button = button
                #endif
                config.button.title = CelestiaString("Get Add-ons", comment: "Open webpage for downloading add-ons")
                config.buttonProperties.primaryAction = UIAction { [weak self] _ in
                    guard let self else { return }
                    self.getAddonsHandler()
                }
                contentUnavailableConfiguration = config
            }
        } else {
            contentUnavailableConfiguration = nil
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        selection(item)
    }

    private func reload() {
        isLoading = true
        if #available(iOS 17, *) {
            setNeedsUpdateContentUnavailableConfiguration()
        }
        Task {
            let resourceManager = self.resourceManager
            let items = await Task.detached(priority: .background) {
                resourceManager.installedResources()
            }.value
            reloadUI(items)
            isLoading = false
        }
    }

    private func reloadUI(_ items: [ResourceItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ResourceItem>()
        snapshot.appendSections([.single])
        snapshot.appendItems(items, toSection: .single)
        dataSource.applySnapshotUsingReloadData(snapshot)
        self.items = items
        if #available(iOS 17, visionOS 1, *) {
            setNeedsUpdateContentUnavailableConfiguration()
        } else {
            collectionView.backgroundView = items.isEmpty ? emptyView : nil
        }
    }

    @available(iOS 17, visionOS 1, *)
    private func emptyViewConfiguration() -> UIContentUnavailableConfiguration? {
        var config = UIContentUnavailableConfiguration.empty()
        config.text = CelestiaString("Enhance Celestia with online add-ons", comment: "")
        #if !targetEnvironment(macCatalyst)
        let button = UIButton.Configuration.filled()
        config.button = button
        #endif
        config.button.title = CelestiaString("Get Add-ons", comment: "Open webpage for downloading add-ons")
        config.buttonProperties.primaryAction = UIAction { [weak self] _ in
            guard let self else { return }
            self.getAddonsHandler()
        }
        return config
    }
}

extension InstalledResourceViewController {
    @objc private func unzipSuccess(_ notification: Notification) {
        reload()
    }

    @objc private func uninstallSuccess(_ notification: Notification) {
        reload()
    }
}

#if !os(visionOS)
private extension InstalledResourceViewController {
    @objc private func showUpdates() {
        showUpdatesHandler()
    }
}
#endif

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: InstalledResourceViewController.self).bundleIdentifier!
    fileprivate static let updates = NSToolbarItem.Identifier.init("\(prefix).addons.updates")
}

extension InstalledResourceViewController: ToolbarAwareViewController {
    func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier] {
        return [.updates]
    }

    func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        if itemIdentifier == .updates {
            return NSToolbarItem(itemIdentifier: itemIdentifier, buttonTitle: CelestiaString("Updates", comment: "View the list of add-ons that have pending updates."), target: self, action: #selector(showUpdates))
        }
        return nil
    }
}
#endif
