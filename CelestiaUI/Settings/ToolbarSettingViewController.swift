// ToolbarSettingViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

@available(iOS 15, *)
class ToolbarSettingViewController: SubscriptionBackingViewController {
    private class ContentViewController: UICollectionViewController {
        private let userDefaults: UserDefaults
        private let toolbarActionsKey: String
        private let assetProvider: AssetProvider

        private var addedActions: [QuickAction] = []
        private var otherActions: [QuickAction] = []

        init(userDefaults: UserDefaults, toolbarActionsKey: String, assetProvider: AssetProvider) {
            self.userDefaults = userDefaults
            self.toolbarActionsKey = toolbarActionsKey
            self.assetProvider = assetProvider

            var configuration = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
            configuration.footerMode = .supplementary
            super.init(collectionViewLayout: UICollectionViewCompositionalLayout(sectionProvider: { section, environment in
                if section == 1 {
                    var configuration = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
                    configuration.footerMode = .supplementary
                    return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
                }
                return NSCollectionLayoutSection.list(using: .init(appearance: .defaultGrouped), layoutEnvironment: environment)
            }))
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            if let savedValue = userDefaults.string(forKey: toolbarActionsKey) {
                addedActions = QuickAction.from(savedValue) ?? QuickAction.defaultItems
                if !addedActions.contains(.menu) {
                    addedActions.append(.menu)
                }
            } else {
                addedActions = QuickAction.defaultItems
            }

            otherActions = QuickAction.allCases.filter { !addedActions.contains($0) }
            collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "Entry")
            collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "Reset")
            collectionView.register(UICollectionViewListCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer")
        }

        override func setEditing(_ editing: Bool, animated: Bool) {
            super.setEditing(editing, animated: animated)

            collectionView.reloadData()
        }

        override func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
            return indexPath.section == 0
        }

        override func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt currentIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
            guard proposedIndexPath.section == 0 else { return IndexPath(item: addedActions.count - 1, section: 0) }
            if proposedIndexPath.item >= addedActions.count {
                return IndexPath(item: addedActions.count - 1, section: proposedIndexPath.section)
            }
            return proposedIndexPath
        }

        override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            guard destinationIndexPath.section == 0, destinationIndexPath.item < addedActions.count else { 
                collectionView.reloadData()
                return
            }
            addedActions.insert(addedActions.remove(at: sourceIndexPath.item), at: destinationIndexPath.item)
            userDefaults.set(QuickAction.toString(addedActions), forKey: toolbarActionsKey)
        }

        override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
            return indexPath.section == 0 && indexPath.item < addedActions.count
        }

        override func numberOfSections(in collectionView: UICollectionView) -> Int {
            return collectionView.isEditing ? 1 : 2
        }

        override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            if section == 1 { return 1 }
            if collectionView.isEditing {
                return addedActions.count + otherActions.count
            }
            return addedActions.count
        }

        override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            if indexPath.section == 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Reset", for: indexPath) as! UICollectionViewListCell
                var configuration = UIListContentConfiguration.celestiaCell()
                #if targetEnvironment(macCatalyst)
                configuration.textProperties.color = cell.tintColor
                #else
                configuration.textProperties.color = .themeLabel
                #endif
                configuration.text = CelestiaString("Reset to Default", comment: "Reset celestia.cfg, data directory location")
                cell.contentConfiguration = configuration
                return cell
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Entry", for: indexPath) as! UICollectionViewListCell
            let action: QuickAction
            if indexPath.item >= addedActions.count {
                action = otherActions[indexPath.item - addedActions.count]
            } else {
                action = addedActions[indexPath.item]
            }
            var configuration = UIListContentConfiguration.celestiaCell()
            configuration.text = action.title
            configuration.image = action.image(with: assetProvider)
            configuration.imageProperties.tintColor = .label
            configuration.imageProperties.maximumSize = CGSize(width: GlobalConstants.listItemIconSize, height: GlobalConstants.listItemIconSize)
            cell.contentConfiguration = configuration
            if indexPath.item < addedActions.count {
                if action.deletable {
                    cell.accessories = [.delete(displayed: .whenEditing, actionHandler: { [weak self] in
                        guard let self else { return }
                        guard let item = self.addedActions.firstIndex(of: action) else { return }
                        let indexPath = IndexPath(item: item, section: 0)
                        self.addedActions.remove(at: indexPath.item)
                        let insertionIndex = self.otherActions.firstIndex(where: { $0.rawValue > action.rawValue }) ?? 0
                        self.otherActions.insert(action, at: insertionIndex)
                        self.userDefaults.set(QuickAction.toString(self.addedActions), forKey: self.toolbarActionsKey)
                        collectionView.performBatchUpdates {
                            collectionView.deleteItems(at: [indexPath])
                            collectionView.insertItems(at: [IndexPath(item: self.addedActions.count + insertionIndex, section: indexPath.section)])
                        }
                    }), .reorder(displayed: .whenEditing)]
                } else {
                    cell.accessories = [.reorder(displayed: .whenEditing)]
                }
            } else {
                cell.accessories = [.insert(displayed: .whenEditing, actionHandler: { [weak self] in
                    guard let self else { return }
                    guard let item = self.otherActions.firstIndex(of: action) else { return }
                    let indexPath = IndexPath(item: addedActions.count + item, section: 0)
                    self.addedActions.append(self.otherActions.remove(at: indexPath.item - self.addedActions.count))
                    self.userDefaults.set(QuickAction.toString(self.addedActions), forKey: self.toolbarActionsKey)
                    collectionView.performBatchUpdates {
                        collectionView.deleteItems(at: [indexPath])
                        collectionView.insertItems(at: [IndexPath(item: self.addedActions.count - 1, section: indexPath.section)])
                    }
                })]
            }
            return cell
        }

        override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
            return indexPath.item == 1
        }

        override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            collectionView.deselectItem(at: indexPath, animated: true)
            guard indexPath.section == 1, indexPath.item == 0 else { return }

            userDefaults.set(nil, forKey: toolbarActionsKey)
            addedActions = QuickAction.defaultItems
            otherActions = QuickAction.allCases.filter { !addedActions.contains($0) }
            collectionView.reloadData()
        }

        override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath) as! UICollectionViewListCell
            var configuration = UIListContentConfiguration.groupedFooter()
            configuration.text = CelestiaString("Configuration will take effect after a restart.", comment: "Change requires a restart")
            cell.contentConfiguration = configuration
            return cell
        }
    }

    init(context: ToolbarSettingContext, userDefaults: UserDefaults, subscriptionManager: SubscriptionManager, assetProvider: AssetProvider, openSubscriptionManagement: @escaping () -> Void) {
        super.init(subscriptionManager: subscriptionManager, openSubscriptionManagement: openSubscriptionManagement) { containerViewController in
            containerViewController.navigationItem.rightBarButtonItem = containerViewController.editButtonItem
            return ContentViewController(userDefaults: userDefaults, toolbarActionsKey: context.toolbarActionsKey, assetProvider: assetProvider)
        }
        title = CelestiaString("Toolbar", comment: "Toolbar customization entry in Settings")
        windowTitle = title
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        currentViewController?.setEditing(editing, animated: animated)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
