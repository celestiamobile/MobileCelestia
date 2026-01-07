//
// AddonUpdateListViewController.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import Combine
import UIKit

final class AddonUpdateListContainerViewController: SubscriptionBackingViewController {
    init(addonUpdateManager: AddonUpdateManager, resourceManager: ResourceManager, subscriptionManager: SubscriptionManager, openAddon: @escaping (ResourceItem) -> Void, openSubscriptionManagement: @escaping () -> Void) {
        super.init(subscriptionManager: subscriptionManager, openSubscriptionManagement: openSubscriptionManagement) { _ in
            AddonUpdateListViewController(addonUpdateManager: addonUpdateManager, resourceManager: resourceManager, subscriptionManager: subscriptionManager, openAddon: openAddon)
        }

        title = CelestiaString("Updates", comment: "View the list of add-ons that have pending updates.")
        windowTitle = title
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: UIImage(systemName: "questionmark.circle"), style: .plain, target: self, action: #selector(showHelp))
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func showHelp() {
        guard let vc = currentViewController as? AddonUpdateListViewController else { return }
        vc.showHelp()
    }

    @objc private func refreshTriggered() {
        guard let vc = currentViewController as? AddonUpdateListViewController else { return }
        vc.refreshTriggered()
    }
}

final class AddonUpdateListViewController: UICollectionViewController {
    private let addonUpdateManager: AddonUpdateManager
    private let resourceManager: ResourceManager
    private let subscriptionManager: SubscriptionManager
    private let openAddon: (ResourceItem) -> Void

    private enum Section {
        case single
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, AddonUpdateManager.PendingAddonUpdate> = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AddonUpdateManager.PendingAddonUpdate> { cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.cell()
            contentConfiguration.text = itemIdentifier.addon.name
            contentConfiguration.secondaryText = dateFormatter.string(from: itemIdentifier.update.modificationDate)
            contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: GlobalConstants.listItemMediumMarginVertical, leading: GlobalConstants.listItemMediumMarginHorizontal, bottom: GlobalConstants.listItemMediumMarginVertical, trailing: GlobalConstants.listItemMediumMarginHorizontal)
            cell.contentConfiguration = contentConfiguration
            cell.accessories = [.disclosureIndicator()]
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, AddonUpdateManager.PendingAddonUpdate>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        return dataSource
    }()

    #if !targetEnvironment(macCatalyst)
    private lazy var refreshControl = UIRefreshControl()
    private lazy var cancellables: Set<AnyCancellable> = []
    #endif

    init(addonUpdateManager: AddonUpdateManager, resourceManager: ResourceManager, subscriptionManager: SubscriptionManager, openAddon: @escaping (ResourceItem) -> Void) {
        self.addonUpdateManager = addonUpdateManager
        self.resourceManager = resourceManager
        self.subscriptionManager = subscriptionManager
        self.openAddon = openAddon
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .defaultGrouped)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = CelestiaString("Updates", comment: "View the list of add-ons that have pending updates.")
        windowTitle = title

        collectionView.dataSource = dataSource

        #if !targetEnvironment(macCatalyst)
        refreshControl.addTarget(self, action: #selector(refreshTriggered), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        if addonUpdateManager.isCheckingUpdates {
            refreshControl.beginRefreshing()
        }
        addonUpdateManager.$isCheckingUpdates.removeDuplicates().sink { [weak self] refreshing in
            guard let self else { return }
            if refreshing {
                self.refreshControl.beginRefreshing()
            } else {
                self.refreshControl.endRefreshing()
            }
        }
        .store(in: &cancellables)
        #endif

        if #available(iOS 17, visionOS 1, *) {
            setNeedsUpdateContentUnavailableConfiguration()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(unzipSuccess(_:)), name: ResourceManager.unzipSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uninstallSuccess(_:)), name: ResourceManager.uninstallSuccess, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refresh(checkReason: .viewAppear)
    }

    @available(iOS 17, visionOS 1, *)
    override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
        if !addonUpdateManager.pendingUpdates.isEmpty {
            contentUnavailableConfiguration = nil
        } else {
            var config = UIContentUnavailableConfiguration.empty()
            config.text = CelestiaString("No Update Available", comment: "Hint that there is no update for installed add-ons.")
            contentUnavailableConfiguration = config
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        openAddon(item.addon)
    }
}

extension AddonUpdateListViewController {
    func showHelp() {
        showError(
            CelestiaString("Add-on Updates", comment: ""),
            detail: CelestiaString("Add-on updates are only supported for add-ons installed on version 1.9.3 or above.", comment: "Hint for requirement for updating add-ons.")
        )
    }

    @objc func refreshTriggered() {
        refresh(checkReason: .refresh)
    }

    @objc private func unzipSuccess(_ notification: Notification) {
        refresh(checkReason: .change)
    }

    @objc private func uninstallSuccess(_ notification: Notification) {
        refresh(checkReason: .change)
    }
}

private extension AddonUpdateListViewController {
    private func refresh(checkReason: AddonUpdateManager.CheckReason) {
        guard let (transactionID, isSandbox) = subscriptionManager.transactionInfo() else { return }
        Task {
            let success = await addonUpdateManager.refresh(reason: checkReason, originalTransactionID: transactionID, sandbox: isSandbox, language: AppCore.language)
            if !success {
                showError(
                    CelestiaString("Error checking updates", comment: "Encountered error while checking updates."),
                    detail: CelestiaString("Please ensure you have a valid Celestia PLUS subscription or check again later.", comment: "Encountered error while checking updates, possible recovery instruction.")
                )
            }

            reload()
            if #available(iOS 17, visionOS 1, *) {
                setNeedsUpdateContentUnavailableConfiguration()
            }
        }
    }

    private func reload() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, AddonUpdateManager.PendingAddonUpdate>()
        snapshot.appendSections([.single])
        snapshot.appendItems(addonUpdateManager.pendingUpdates, toSection: .single)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: AddonUpdateListContainerViewController.self).bundleIdentifier!
    fileprivate static let help = NSToolbarItem.Identifier.init("\(prefix).addons.updates.help")
    fileprivate static let refresh = NSToolbarItem.Identifier.init("\(prefix).addons.updates.refresh")
}

extension AddonUpdateListContainerViewController: ToolbarAwareViewController {
    func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier] {
        return [.refresh, .help]
    }

    func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        if itemIdentifier == .refresh {
            return NSToolbarItem(itemIdentifier: .refresh, systemImageName: "arrow.clockwise", accessibilityDescription: CelestiaString("Refresh", comment: "Button to refresh this list"), target: self, action: #selector(refreshTriggered))
        }
        if itemIdentifier == .help {
            return NSToolbarItem(itemIdentifier: .help, systemImageName: "questionmark", accessibilityDescription: CelestiaString("Help", comment: ""), target: self, action: #selector(showHelp))
        }
        return nil
    }
}
#endif
