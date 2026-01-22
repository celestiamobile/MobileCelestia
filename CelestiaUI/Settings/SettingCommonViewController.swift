// SettingCommonViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaFoundation
import UIKit

class SettingCommonViewController: UICollectionViewController {
    private let item: SettingCommonItem

    private let core: AppCore
    private let executor: AsyncProviderExecutor
    private let userDefaults: UserDefaults

    init(core: AppCore, executor: AsyncProviderExecutor, userDefaults: UserDefaults, item: SettingCommonItem) {
        self.item = item
        self.core = core
        self.executor = executor
        self.userDefaults = userDefaults

        super.init(collectionViewLayout: UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
            if item.sections[sectionIndex].header != nil {
                configuration.headerMode = .supplementary
            }
            if item.sections[sectionIndex].footer != nil {
                configuration.footerMode = .supplementary
            }
            return .list(using: configuration, layoutEnvironment: environment)
        }))
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
        title = item.title
        windowTitle = title

        collectionView.register(SelectableListCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.register(UICollectionViewListCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.register(UICollectionViewListCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer")
    }
}

extension SettingCommonViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return item.sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return item.sections[section].rows.count
    }

    private func logWrongAssociatedItemType(_ item: AnyHashable) -> Never {
        fatalError("Wrong associated item \(item.base)")
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let row = item.sections[indexPath.section].rows[indexPath.item]

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! SelectableListCell

        let configuration: any UIContentConfiguration
        var accessories: [UICellAccessory] = []
        var selectable = false
        switch row.associatedItem {
        case let .slider(item):
            let maxValue = item.maxValue
            let minValue = item.minValue
            let key = item.key
            var listConfiguration = UIListContentConfiguration.celestiaCell()
            listConfiguration.text = row.name
            let value = ((core.value(forKey: key) as! Double) - minValue) / (maxValue - minValue)
            configuration = SliderConfiguration(
                listContent: listConfiguration,
                value: value
            ) { [weak self] newValue in
                guard let self = self else { return }
                let transformed = newValue * (maxValue - minValue) + minValue
                Task {
                    await self.executor.run {
                        $0.setValue(transformed, forKey: key)
                    }
                    self.userDefaults.set(transformed, forKey: key)
                }
            }
        case .action:
            var cellConfiguration = UIListContentConfiguration.celestiaCell()
            cellConfiguration.text = row.name
            configuration = cellConfiguration
            selectable = true
        case .custom:
            var cellConfiguration = UIListContentConfiguration.celestiaCell()
            cellConfiguration.text = row.name
            configuration = cellConfiguration
            selectable = true
        case let .checkmark(item):
            let enabled = core.value(forKey: item.key) as? Bool ?? false
            var cellConfiguration = UIListContentConfiguration.celestiaCell()
            cellConfiguration.text = row.name
            cellConfiguration.secondaryText = row.subtitle
            configuration = cellConfiguration
            if item.representation == .switch {
                let toggle = UISwitch()
                toggle.isOn = enabled
                toggle.addAction(UIAction { [weak self] action in
                    guard let self, let sender = action.sender as? UISwitch else { return }
                    let newValue = sender.isOn
                    Task {
                        await self.executor.run {
                            $0.setValue(newValue, forKey: item.key)
                        }
                        self.userDefaults.setValue(newValue, forKey: item.key)
                    }
                }, for: .valueChanged)
                accessories = [.customView(configuration: UICellAccessory.CustomViewConfiguration(customView: toggle, placement: .trailing(displayed: .always)))]
            } else {
                accessories = enabled ? [.checkmark()] : []
                selectable = true
            }
        case let .keyedSelection(item):
            let selectedIndex = core.value(forKey: item.key) as? Int ?? 0
            var cellConfiguration = UIListContentConfiguration.celestiaCell()
            cellConfiguration.text = row.name
            configuration = cellConfiguration
            accessories = selectedIndex == item.index ? [.checkmark()] : []
            selectable = true
        case let .prefSwitch(item):
            let enabled = userDefaults[item.key] ?? item.defaultOn
            var cellConfiguration = UIListContentConfiguration.celestiaCell()
            cellConfiguration.text = row.name
            cellConfiguration.secondaryText = row.subtitle
            configuration = cellConfiguration

            let toggle = UISwitch()
            toggle.isOn = enabled
            toggle.addAction(UIAction { [weak self] action in
                guard let self, let sender = action.sender as? UISwitch else { return }
                let newValue = sender.isOn
                Task {
                    self.userDefaults[item.key] = newValue
                }
            }, for: .valueChanged)
            accessories = [.customView(configuration: UICellAccessory.CustomViewConfiguration(customView: toggle, placement: .trailing(displayed: .always)))]
        case let .prefSelection(item):
            let currentValue = self.userDefaults[item.key] ?? item.defaultOption
            var cellConfiguration = UIListContentConfiguration.celestiaCell()
            cellConfiguration.text = row.name
            cellConfiguration.secondaryText = row.subtitle
            configuration = cellConfiguration

            if #available(iOS 16, *) {
                if let selectedIndex = item.options.firstIndex(where: { $0.value == currentValue }) {
                    accessories.append(.label(text: item.options[selectedIndex].name))
                }
                accessories.append(.popUpMenu(UIMenu(children: item.options.map { option in
                    UIAction(title: option.name, state: currentValue == option.value ? .on : .off) { [weak self] _ in
                        guard let self else { return }
                        self.userDefaults[item.key] = option.value
                        self.collectionView.reloadData()
                    }
                })))
            } else {
                let button = UIButton(configuration: .plain())
                button.showsMenuAsPrimaryAction = true
                button.changesSelectionAsPrimaryAction = true
                button.menu = UIMenu(children: item.options.map({ option in
                    UIAction(title: option.name, state: currentValue == option.value ? .on : .off) { [weak self] _ in
                        guard let self else { return }
                        self.userDefaults[item.key] = option.value
                    }
                }))
                accessories = [
                    .customView(configuration: UICellAccessory.CustomViewConfiguration(customView: button, placement: .trailing(displayed: .always))),
                ]
            }
        case let .selection(item):
            let currentValue = core.value(forKey: item.key) as? Int ?? item.defaultOption
            var cellConfiguration = UIListContentConfiguration.celestiaCell()
            cellConfiguration.text = row.name
            cellConfiguration.secondaryText = row.subtitle
            configuration = cellConfiguration

            if #available(iOS 16, *) {
                if let selectedIndex = item.options.firstIndex(where: { $0.value == currentValue }) {
                    accessories.append(.label(text: item.options[selectedIndex].name))
                }
                accessories.append(.popUpMenu(UIMenu(children: item.options.map { option in
                    UIAction(title: option.name, state: currentValue == option.value ? .on : .off) { [weak self] _ in
                        guard let self else { return }
                        Task {
                            await self.executor.run {
                                $0.setValue(option.value, forKey: item.key)
                            }
                            self.userDefaults.setValue(option.value, forKey: item.key)
                            self.collectionView.reloadData()
                        }
                    }
                })))
            } else {
                let button = UIButton(configuration: .plain())
                button.showsMenuAsPrimaryAction = true
                button.changesSelectionAsPrimaryAction = true
                button.menu = UIMenu(children: item.options.map({ option in
                    UIAction(title: option.name, state: currentValue == option.value ? .on : .off) { [weak self] _ in
                        guard let self else { return }
                        Task {
                            await self.executor.run {
                                $0.setValue(option.value, forKey: item.key)
                            }
                            self.userDefaults.setValue(option.value, forKey: item.key)
                        }
                    }
                }))
                accessories = [
                    .customView(configuration: UICellAccessory.CustomViewConfiguration(customView: button, placement: .trailing(displayed: .always))),
                ]
            }
        case let .prefSlider(item):
            let maxValue = item.maxValue
            let minValue = item.minValue
            var listConfiguration = UIListContentConfiguration.celestiaCell()
            listConfiguration.text = row.name
            listConfiguration.secondaryText = row.subtitle
            let currentValue = self.userDefaults[item.key] ?? item.defaultValue
            let value = (currentValue - minValue) / (maxValue - minValue)
            configuration = SliderConfiguration(
                listContent: listConfiguration,
                value: value
            ) { [weak self] newValue in
                guard let self = self else { return }
                let transformed = newValue * (maxValue - minValue) + minValue
                self.userDefaults[item.key] = transformed
            }
        case .common, .other:
            fatalError("SettingCommonViewController cannot handle this type of item")
        }

        cell.contentConfiguration = configuration
        cell.accessories = accessories
        cell.selectable = selectable
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let row = item.sections[indexPath.section].rows[indexPath.row]
        switch row.associatedItem {
        case .action(let item):
            core.charEnter(item.action)
        case .checkmark(let item):
            Task {
                let checked = core.value(forKey: item.key) as? Bool ?? false
                await executor.run {
                    $0.setValue(!checked, forKey: item.key)
                }
                self.userDefaults.set(!checked, forKey: item.key)
                self.collectionView.reloadData()
            }
        case .keyedSelection(let item):
            Task {
                await executor.run {
                    $0.setValue(item.index, forKey: item.key)
                }
                self.userDefaults.set(item.index, forKey: item.key)
                self.collectionView.reloadData()
            }
        case .custom(let item):
            Task {
                await executor.run {
                    item.block($0)
                }
            }
        case .prefSelection:
            break
        case .selection:
            break
        default:
            break
        }
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! UICollectionViewListCell
            var contentConfiguration = UIListContentConfiguration.groupedHeader()
            contentConfiguration.text = item.sections[indexPath.section].header
            cell.contentConfiguration = contentConfiguration
            return cell
        } else if kind == UICollectionView.elementKindSectionFooter {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath) as! UICollectionViewListCell
            var contentConfiguration = UIListContentConfiguration.groupedFooter()
            contentConfiguration.text = item.sections[indexPath.section].footer
            cell.contentConfiguration = contentConfiguration
            return cell
        }
        fatalError()
    }
}
