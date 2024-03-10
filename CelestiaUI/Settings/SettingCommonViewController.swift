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
import CelestiaFoundation
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
        if #available(iOS 15, visionOS 1, *) {
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

        switch row.associatedItem {
        case .slider(let item):
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
                    self.userDefaults.set(transformed, forKey: key)
                    self.tableView.reloadData()
                }
            }
            return cell
        case .action:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Action", for: indexPath) as! TextCell
            cell.title = row.name
            return cell
        case .custom:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Custom", for: indexPath) as! TextCell
            cell.title = row.name
            return cell
        case .checkmark(let item):
            let enabled = core.value(forKey: item.key) as? Bool ?? false
            if item.representation == .switch {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath) as! SwitchCell
                cell.title = row.name
                cell.subtitle = row.subtitle
                cell.enabled = enabled
                cell.toggleBlock = { [weak self] newValue in
                    guard let self else { return }
                    Task {
                        await self.executor.run {
                            $0.setValue(newValue, forKey: item.key)
                        }
                        self.userDefaults.setValue(newValue, forKey: item.key)
                    }
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkmark", for: indexPath) as! TextCell
                cell.title = row.name
                cell.subtitle = row.subtitle
                cell.accessoryType = enabled ? .checkmark : .none
                return cell
            }
        case .keyedSelection(let item):
            let selectedIndex = core.value(forKey: item.key) as? Int ?? 0
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkmark", for: indexPath) as! TextCell
            cell.title = row.name
            cell.accessoryType = selectedIndex == item.index ? .checkmark : .none
            return cell
        case .prefSwitch(let item):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath) as! SwitchCell
            cell.enabled = userDefaults[item.key] ?? item.defaultOn
            cell.title = row.name
            cell.subtitle = row.subtitle
            cell.toggleBlock = { [weak self] enabled in
                guard let self else { return }
                self.userDefaults[item.key] = enabled
            }
            return cell
        case .prefSelection(let item):
            let currentValue = self.userDefaults[item.key] ?? item.defaultOption
            if #available(iOS 15, visionOS 1, *) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Selection15", for: indexPath) as! SelectionCell
                cell.title = row.name
                cell.subtitle = row.subtitle
                cell.selectionData = SelectionCell.SelectionData(options: item.options.map { $0.name }, selectedIndex: item.options.firstIndex(where: { $0.value == currentValue }) ?? -1)
                cell.selectionChange = { [weak self] index in
                    guard let self else { return }
                    self.userDefaults[item.key] = item.options[index].value
                }
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "Selection", for: indexPath) as! TextCell
            cell.title = row.name
            cell.subtitle = row.subtitle
            cell.detail = item.options.first(where: { $0.value == currentValue })?.name ?? ""
            cell.accessoryType = .disclosureIndicator
            return cell
        case .selection(let item):
            let currentValue = core.value(forKey: item.key) as? Int ?? item.defaultOption
            if #available(iOS 15, visionOS 1, *) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Selection15", for: indexPath) as! SelectionCell
                cell.title = row.name
                cell.subtitle = row.subtitle
                cell.selectionData = SelectionCell.SelectionData(options: item.options.map { $0.name }, selectedIndex: item.options.firstIndex(where: { $0.value == currentValue }) ?? -1)
                cell.selectionChange = { [weak self] index in
                    guard let self else { return }
                    Task {
                        let value = item.options[index].value
                        await self.executor.run {
                            $0.setValue(value, forKey: item.key)
                        }
                        self.userDefaults.setValue(value, forKey: item.key)
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
        case .prefSlider(let item):
            let maxValue = item.maxValue
            let minValue = item.minValue
            let cell = tableView.dequeueReusableCell(withIdentifier: "Slider", for: indexPath) as! SliderCell
            cell.title = row.name
            let currentValue = self.userDefaults[item.key] ?? item.defaultValue
            let transformedValue = (currentValue - minValue) / (maxValue - minValue)
            cell.value = transformedValue
            cell.subtitle = row.subtitle
            cell.valueChangeBlock = { [weak self] (value) in
                guard let self = self else { return }
                let transformed = value * (maxValue - minValue) + minValue
                self.userDefaults[item.key] = transformed
            }
            return cell
        case .common, .other:
            fatalError("SettingCommonViewController cannot handle this type of item")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = item.sections[indexPath.section].rows[indexPath.row]
        switch row.associatedItem {
        case .action(let item):
            core.charEnter(item.action)
        case .checkmark(let item):
            guard let cell = tableView.cellForRow(at: indexPath) else { break }
            let checked = cell.accessoryType == .checkmark
            Task {
                await executor.run {
                    $0.setValue(!checked, forKey: item.key)
                }
                self.userDefaults.set(!checked, forKey: item.key)
                self.tableView.reloadData()
            }
        case .keyedSelection(let item):
            Task {
                await executor.run {
                    $0.setValue(item.index, forKey: item.key)
                }
                self.userDefaults.set(item.index, forKey: item.key)
                self.tableView.reloadData()
            }
        case .custom(let item):
            Task {
                await executor.run {
                    item.block($0)
                }
            }
        case .prefSelection(let item):
            if #available(iOS 15, visionOS 1, *) {
                break
            }
            let currentValue = userDefaults[item.key] ?? item.defaultOption
            let vc = SelectionViewController(title: row.name, options: item.options.map { $0.name }, selectedIndex: item.options.firstIndex(where: { $0.value == currentValue })) { [weak self] newIndex in
                guard let self else { return }
                self.userDefaults[item.key] = item.options[newIndex].value
                self.tableView.reloadData()
            }
            navigationController?.pushViewController(vc, animated: true)
        case .selection(let item):
            if #available(iOS 15, visionOS 1, *) {
                break
            }
            let currentValue = core.value(forKey: item.key) as? Int ?? item.defaultOption
            let vc = SelectionViewController(title: row.name, options: item.options.map { $0.name }, selectedIndex: item.options.firstIndex(where: { $0.value == currentValue })) { [weak self] newIndex in
                guard let self else { return }
                Task {
                    let value = item.options[newIndex].value
                    await self.executor.run {
                        $0.setValue(value, forKey: item.key)
                    }
                    self.userDefaults.set(value, forKey: item.key)
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
