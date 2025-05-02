//
// ToolbarSettingViewController.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

@available(iOS 15, *)
class ToolbarSettingViewController: SubscriptionBackingViewController {
    private class ContentViewController: BaseTableViewController {
        private let userDefaults: UserDefaults
        private let toolbarActionsKey: String
        private let assetProvider: AssetProvider

        private var addedActions: [QuickAction] = []
        private var otherActions: [QuickAction] = []

        init(userDefaults: UserDefaults, toolbarActionsKey: String, assetProvider: AssetProvider) {
            self.userDefaults = userDefaults
            self.toolbarActionsKey = toolbarActionsKey
            self.assetProvider = assetProvider

            super.init(style: .defaultGrouped)
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
        }

        override func setEditing(_ editing: Bool, animated: Bool) {
            super.setEditing(editing, animated: animated)

            tableView.reloadData()
        }

        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return indexPath.section == 0
        }

        override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
            guard proposedDestinationIndexPath.section == 0 else { return IndexPath(row: addedActions.count - 1, section: 0) }
            if proposedDestinationIndexPath.row >= addedActions.count {
                return IndexPath(row: addedActions.count - 1, section: proposedDestinationIndexPath.section)
            }
            return proposedDestinationIndexPath
        }

        override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
            guard indexPath.section == 0 else { return .none }
            if indexPath.row < addedActions.count {
                return addedActions[indexPath.row].deletable ? .delete : .none
            }
            return .insert
        }

        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            guard indexPath.section == 0 else { return }
            switch editingStyle {
            case .delete:
                let action = addedActions.remove(at: indexPath.row)
                let insertionIndex = otherActions.firstIndex(where: { $0.rawValue > action.rawValue }) ?? 0
                otherActions.insert(action, at: insertionIndex)
                userDefaults.set(QuickAction.toString(addedActions), forKey: toolbarActionsKey)
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .bottom)
                tableView.insertRows(at: [IndexPath(item: addedActions.count + insertionIndex, section: indexPath.section)], with: .top)
                tableView.endUpdates()
                break
            case .insert:
                addedActions.append(otherActions.remove(at: indexPath.row - addedActions.count))
                userDefaults.set(QuickAction.toString(addedActions), forKey: toolbarActionsKey)
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .top)
                tableView.insertRows(at: [IndexPath(item: addedActions.count - 1, section: indexPath.section)], with: .bottom)
                tableView.endUpdates()
                break
            case .none:
                break
            @unknown default:
                break
            }
        }

        override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            guard destinationIndexPath.section == 0, destinationIndexPath.row < addedActions.count else { 
                tableView.reloadData()
                return
            }
            addedActions.insert(addedActions.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
            userDefaults.set(QuickAction.toString(addedActions), forKey: toolbarActionsKey)
        }

        override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            return indexPath.section == 0 && indexPath.row < addedActions.count
        }

        override func numberOfSections(in tableView: UITableView) -> Int {
            return tableView.isEditing ? 1 : 2
        }

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if section == 1 { return 1 }
            if tableView.isEditing {
                return addedActions.count + otherActions.count
            }
            return addedActions.count
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell: UITableViewCell
            if let c = tableView.dequeueReusableCell(withIdentifier: "Cell") {
                cell = c
            } else {
                cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
            }
            if indexPath.section == 1 {
                var configuration = UIListContentConfiguration.cell()
                #if targetEnvironment(macCatalyst)
                configuration.textProperties.color = cell.tintColor
                #else
                configuration.textProperties.color = .themeLabel
                #endif
                configuration.text = CelestiaString("Reset to Default", comment: "Reset celestia.cfg, data directory location")
                cell.contentConfiguration = configuration
                cell.selectionStyle = .default
                return cell
            }
            let action: QuickAction
            if indexPath.row >= addedActions.count {
                action = otherActions[indexPath.row - addedActions.count]
            } else {
                action = addedActions[indexPath.row]
            }
            var configuration = UIListContentConfiguration.cell()
            configuration.text = action.title
            configuration.image = action.image(with: assetProvider)
            configuration.imageProperties.tintColor = .label
            configuration.imageProperties.maximumSize = CGSize(width: GlobalConstants.listItemIconSize, height: GlobalConstants.listItemIconSize)
            cell.contentConfiguration = configuration
            cell.selectionStyle = .none
            return cell
        }

        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            guard indexPath.section == 1, indexPath.row == 0 else { return }

            userDefaults.set(nil, forKey: toolbarActionsKey)
            addedActions = QuickAction.defaultItems
            otherActions = QuickAction.allCases.filter { !addedActions.contains($0) }
            tableView.reloadData()
        }

        override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            if section == 1 {
                return CelestiaString("Configuration will take effect after a restart.", comment: "Change requires a restart")
            }
            return nil
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
