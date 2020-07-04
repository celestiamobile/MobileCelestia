//
// SettingCommonViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

import CelestiaCore

class SettingCommonViewController: UIViewController {
    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private let item: SettingCommonItem

    private lazy var core = CelestiaAppCore.shared

    init(item: SettingCommonItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground

        title = item.title
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

private extension SettingCommonViewController {
    func setup() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.separatorColor = .darkSeparator

        tableView.register(SettingSliderCell.self, forCellReuseIdentifier: "Slider")
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Action")
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Checkmark")
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Custom")
        tableView.register(SettingSwitchCell.self, forCellReuseIdentifier: "Switch")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension SettingCommonViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return item.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return item.sections[section].rows.count
    }

    private func logWrongAssociatedItemType(_ item: AnyHashable) -> Never {
        fatalError("Wrong associated item \(item.base)")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = item.sections[indexPath.section].rows[indexPath.row]

        switch row.type {
        case .slider:
            if let item = row.associatedItem.base as? AssociatedSliderItem {
                let maxValue = item.maxValue
                let minValue = item.minValue
                let key = item.key
                let cell = tableView.dequeueReusableCell(withIdentifier: "Slider", for: indexPath) as! SettingSliderCell
                cell.title = row.name
                cell.value = ((core.value(forKey: key) as! Double) - minValue) / (maxValue - minValue)
                cell.valueChangeBlock = { [weak self] (value) in
                    guard let self = self else { return }
                    let transformed = value * (maxValue - minValue) + minValue
                    self.core.setValue(transformed, forKey: key)
                    self.tableView.reloadData()
                }
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .action:
            if row.associatedItem.base is AssociatedActionItem {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Action", for: indexPath) as! SettingTextCell
                cell.title = row.name
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .custom:
            if row.associatedItem.base is AssociatedCustomItem {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Custom", for: indexPath) as! SettingTextCell
                cell.title = row.name
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .checkmark:
            if let item = row.associatedItem.base as? AssociatedCheckmarkItem {
                let enabled = core.value(forKey: item.key) as? Bool ?? false
                if item.representation == .switch {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath) as! SettingSwitchCell
                    cell.title = row.name
                    cell.enabled = enabled
                    cell.toggleBlock = { [weak self] newValue in
                        guard let self = self else { return }
                        self.core.setValue(newValue, forKey: item.key)
                    }
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkmark", for: indexPath) as! SettingTextCell
                    cell.title = row.name
                    cell.accessoryType = enabled ? .checkmark : .none
                    return cell
                }
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        case .prefSwitch:
            if let item = row.associatedItem.base as? AssociatedPreferenceSwitchItem {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath) as! SettingSwitchCell
                cell.enabled = UserDefaults.app[item.key] ?? false
                cell.title = row.name
                cell.toggleBlock = { (enabled) in
                    UserDefaults.app[item.key] = enabled
                }
                return cell
            } else {
                logWrongAssociatedItemType(row.associatedItem)
            }
        default:
            fatalError("SettingCommonViewController cannot handle this type of item")
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = item.sections[indexPath.section].rows[indexPath.row]
        switch row.type {
        case .action:
            guard let item = row.associatedItem.base as? AssociatedActionItem else { break }
            CelestiaAppCore.shared.charEnter(item.action)
        case .checkmark:
            guard let item = row.associatedItem.base as? AssociatedCheckmarkItem, item.representation == .checkmark else { break }
            guard let cell = tableView.cellForRow(at: indexPath) else { break }
            let checked = cell.accessoryType == .checkmark
            core.setValue(!checked, forKey: item.key)
            tableView.reloadData()
        case .custom:
            guard let item = row.associatedItem.base as? AssociatedCustomItem else { break }
            item.block(core)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType = item.sections[indexPath.section].rows[indexPath.row].type
        switch rowType {
        case .slider:
            return 88
        default:
            return 44
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return item.sections[section].footer
    }
}
