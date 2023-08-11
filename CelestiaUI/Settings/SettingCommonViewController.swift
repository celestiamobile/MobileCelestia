//
// SettingCommonViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

class SettingCommonViewController: BaseTableViewController {
    private let item: SettingCommonItem

    private let core: AppCore
    private let executor: AsyncProviderExecutor
    private let userDefaults: UserDefaults

    init(core: AppCore, executor: AsyncProviderExecutor, userDefaults: UserDefaults, item: SettingCommonItem) {
        self.item = item
        self.core = core
        self.executor = executor
        self.userDefaults = userDefaults
        super.init(style: .defaultGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension SettingCommonViewController {
    func setUp() {
        tableView.register(SliderCell.self, forCellReuseIdentifier: "Slider")
        tableView.register(TextCell.self, forCellReuseIdentifier: "Action")
        tableView.register(TextCell.self, forCellReuseIdentifier: "Checkmark")
        tableView.register(TextCell.self, forCellReuseIdentifier: "Custom")
        tableView.register(SwitchCell.self, forCellReuseIdentifier: "Switch")
        tableView.register(TextCell.self, forCellReuseIdentifier: "Selection")
        if #available(iOS 15, *) {
            tableView.register(SelectionCell.self, forCellReuseIdentifier: "Selection15")
        }
        title = item.title
    }
}

extension SettingCommonViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return item.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return item.sections[section].rows.count
    }

    private func logWrongAssociatedItemType(_ item: AnyHashable) -> Never {
        fatalError("Wrong associated item \(item.base)")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = item.sections[indexPath.section].rows[indexPath.row]

        switch row.type {
        case .slider:
            if let item = row.associatedItem.base as? AssociatedSliderItem {
                let maxValue = item.maxValue
                let minValue = item.minValue
                let key = item.key
                let cell = tableView.dequeueReusableCell(withIdentifier: "Slider", for: indexPath) as! SliderCell
                cell.title = row.name
                cell.value = ((core.value(forKey: key) as! Double) - minValue) / (maxValue - minValue)
                cell.valueChangeBlock = { [weak self] (value) in
                    guard let self = self else { return }
                    let transformed = value * (maxValue - minValue) + minValue
                    Task {
                        await self.executor.run {
                            $0.setValue(transformed, forKey: key)
                        }
                        self.tableView.reloadData()
                    }
                }
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .action:
            if row.associatedItem.base is AssociatedActionItem {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Action", for: indexPath) as! TextCell
                cell.title = row.name
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .custom:
            if row.associatedItem.base is AssociatedCustomItem {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Custom", for: indexPath) as! TextCell
                cell.title = row.name
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .checkmark:
            if let item = row.associatedItem.base as? AssociatedCheckmarkItem {
                let enabled = core.value(forKey: item.key) as? Bool ?? false
                if item.representation == .switch {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath) as! SwitchCell
                    cell.title = row.name
                    cell.enabled = enabled
                    cell.toggleBlock = { [weak self] newValue in
                        guard let self else { return }
                        Task {
                            await self.executor.run {
                                $0.setValue(newValue, forKey: item.key)
                            }
                        }
                    }
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkmark", for: indexPath) as! TextCell
                    cell.title = row.name
                    cell.accessoryType = enabled ? .checkmark : .none
                    return cell
                }
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .keyedSelection:
            if let item = row.associatedItem.base as? AssociatedKeyedSelectionItem {
                let selectedIndex = core.value(forKey: item.key) as? Int ?? 0
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkmark", for: indexPath) as! TextCell
                cell.title = row.name
                cell.accessoryType = selectedIndex == item.index ? .checkmark : .none
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .prefSwitch:
            if let item = row.associatedItem.base as? AssociatedPreferenceSwitchItem {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath) as! SwitchCell
                cell.enabled = userDefaults.value(forKey: item.key) as? Bool ?? item.defaultOn
                cell.title = row.name
                cell.subtitle = row.subtitle
                cell.toggleBlock = { [weak self] enabled in
                    guard let self else { return }
                    self.userDefaults.set(enabled, forKey: item.key)
                }
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .prefSelection:
            if let item = row.associatedItem.base as? AssociatedPreferenceSelectionItem {
                let currentValue: Int = self.userDefaults.value(forKey: item.key) as? Int ?? item.defaultOption
                if #available(iOS 15, *) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Selection15", for: indexPath) as! SelectionCell
                    cell.title = row.name
                    cell.selectionData = SelectionCell.SelectionData(options: item.options.map { $0.name }, selectedIndex: item.options.firstIndex(where: { $0.value == currentValue }) ?? -1)
                    cell.selectionChange = { [weak self] index in
                        guard let self else { return }
                        self.userDefaults.set(item.options[index].value, forKey: item.key)
                    }
                    return cell
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "Selection", for: indexPath) as! TextCell
                cell.title = row.name
                cell.detail = item.options.first(where: { $0.value == currentValue })?.name ?? ""
                cell.accessoryType = .disclosureIndicator
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .selection:
            if let item = row.associatedItem.base as? AssociatedSelectionSingleItem {
                let currentValue = core.value(forKey: item.key) as? Int ?? item.defaultOption
                if #available(iOS 15, *) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Selection15", for: indexPath) as! SelectionCell
                    cell.title = row.name
                    cell.subtitle = row.subtitle
                    cell.selectionData = SelectionCell.SelectionData(options: item.options.map { $0.name }, selectedIndex: item.options.firstIndex(where: { $0.value == currentValue }) ?? -1)
                    cell.selectionChange = { [weak self] index in
                        guard let self else { return }
                        Task {
                            await self.executor.run {
                                $0.setValue(item.options[index].value, forKey: item.key)
                            }
                        }
                    }
                    return cell
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "Selection", for: indexPath) as! TextCell
                cell.title = row.name
                cell.subtitle = row.subtitle
                cell.detail = item.options.first(where: { $0.value == currentValue })?.name ?? ""
                cell.accessoryType = .disclosureIndicator
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .prefSlider:
            if let item = row.associatedItem.base as? AssociatedPreferenceSliderItem {
                let maxValue = item.maxValue
                let minValue = item.minValue
                let cell = tableView.dequeueReusableCell(withIdentifier: "Slider", for: indexPath) as! SliderCell
                cell.title = row.name
                let currentValue: Double = self.userDefaults.value(forKey: item.key) as? Double ?? item.defaultValue
                let transformedValue = (currentValue - minValue) / (maxValue - minValue)
                cell.value = transformedValue
                cell.subtitle = row.subtitle
                cell.valueChangeBlock = { [weak self] (value) in
                    guard let self = self else { return }
                    let transformed = value * (maxValue - minValue) + minValue
                    self.userDefaults.set(transformed, forKey: item.key)
                }
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        default:
            fatalError("SettingCommonViewController cannot handle this type of item")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = item.sections[indexPath.section].rows[indexPath.row]
        switch row.type {
        case .action:
            guard let item = row.associatedItem.base as? AssociatedActionItem else { break }
            core.charEnter(item.action)
        case .checkmark:
            guard let item = row.associatedItem.base as? AssociatedCheckmarkItem, item.representation == .checkmark else { break }
            guard let cell = tableView.cellForRow(at: indexPath) else { break }
            let checked = cell.accessoryType == .checkmark
            Task {
                await executor.run {
                    $0.setValue(!checked, forKey: item.key)
                }
                self.tableView.reloadData()
            }
        case .keyedSelection:
            guard let item = row.associatedItem.base as? AssociatedKeyedSelectionItem else { break }
            Task {
                await executor.run {
                    $0.setValue(item.index, forKey: item.key)
                }
                self.tableView.reloadData()
            }
        case .custom:
            guard let item = row.associatedItem.base as? AssociatedCustomItem else { break }
            Task {
                await executor.run {
                    item.block($0)
                }
            }
        case .prefSelection:
            if #available(iOS 15, *) {
                break
            }
            guard let item = row.associatedItem.base as? AssociatedPreferenceSelectionItem else { break }
            let currentValue: Int = userDefaults.value(forKey: item.key) as? Int ?? item.defaultOption
            let vc = SelectionViewController(title: row.name, options: item.options.map { $0.name }, selectedIndex: item.options.firstIndex(where: { $0.value == currentValue })) { [weak self] newIndex in
                guard let self else { return }
                self.userDefaults.set(item.options[newIndex].value, forKey: item.key)
                self.tableView.reloadData()
            }
            navigationController?.pushViewController(vc, animated: true)
        case .selection:
            if #available(iOS 15, *) {
                break
            }
            guard let item = row.associatedItem.base as? AssociatedSelectionSingleItem else { break }
            let currentValue = core.value(forKey: item.key) as? Int ?? item.defaultOption
            let vc = SelectionViewController(title: row.name, options: item.options.map { $0.name }, selectedIndex: item.options.firstIndex(where: { $0.value == currentValue })) { [weak self] newIndex in
                guard let self else { return }
                Task {
                    await self.executor.run {
                        $0.setValue(item.options[newIndex].value, forKey: item.key)
                    }
                    self.tableView.reloadData()
                }
            }
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return item.sections[section].header
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return item.sections[section].footer
    }
}
