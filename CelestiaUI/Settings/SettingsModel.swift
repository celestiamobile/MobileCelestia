//
// SettingsModel.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import Foundation

public enum SettingType: Hashable {
    case slider
    case action
    case prefSwitch
    case common
    case about
    case render
    case time
    case dataLocation
    case frameRate
    case checkmark
    case custom
    case keyedSelection
    case prefSelection
    case selection
}

public struct SettingItem<T: Hashable>: Hashable {
    public let name: String
    public let type: SettingType
    public let associatedItem: T

    public init(name: String, type: SettingType, associatedItem: T) {
        self.name = name
        self.type = type
        self.associatedItem = associatedItem
    }
}

public struct SettingActionItem: Hashable {
    public let action: Int8

    public init(action: Int8) {
        self.action = action
    }
}

public struct SettingSection: Hashable {
    public let title: String?
    public let items: [SettingItem<AnyHashable>]

    public init(title: String?, items: [SettingItem<AnyHashable>]) {
        self.title = title
        self.items = items
    }
}

public struct SettingCommonItem: Hashable {
    public struct Section: Hashable {
        public let header: String?
        public let rows: [SettingItem<AnyHashable>]
        public let footer: String?

        public init(header: String?, rows: [SettingItem<AnyHashable>], footer: String?) {
            self.header = header
            self.rows = rows
            self.footer = footer
        }
    }

    public let title: String
    public let sections: [Section]
    public init(title: String, sections: [Section]) {
        self.title = title
        self.sections = sections
    }
}

public extension SettingCommonItem {
    init(title: String, items: [SettingItem<AnyHashable>]) {
        self.init(title: title, sections: [Section(header: nil, rows: items, footer: nil)])
    }

    init(item: SettingItem<AnyHashable>) {
        self.init(title: item.name, items: [item])
    }
}

public struct SettingSelectionItem: Hashable {
    public let name: String
    public let index: Int

    public init(name: String, index: Int) {
        self.name = name
        self.index = index
    }
}

public struct SettingKeyedSelectionItem: Hashable {
    public let name: String
    public let key: String
    public let index: Int

    public init(name: String, key: String, index: Int) {
        self.name = name
        self.key = key
        self.index = index
    }
}

public struct SettingSelectionSingleItem: Hashable {
    public struct Option: Hashable {
        public let name: String
        public let value: Int

        public init(name: String, value: Int) {
            self.name = name
            self.value = value
        }
    }

    public let key: String
    public let options: [Option]
    public let defaultOption: Int

    public init(key: String, options: [Option], defaultOption: Int) {
        self.key = key
        self.options = options
        self.defaultOption = defaultOption
    }
}

public struct SettingSliderItem: Hashable {
    public let key: String
    public let minValue: Double
    public let maxValue: Double

    public init(key: String, minValue: Double, maxValue: Double) {
        self.key = key
        self.minValue = minValue
        self.maxValue = maxValue
    }
}

public enum TextItem {
    case short(title: String, detail: String?)
    case long(content: String)
    case link(title: String, url: URL)
}

public struct SettingCheckmarkItem: Hashable {
    public enum Representation: Hashable {
        case checkmark
        case `switch`
    }

    public let name: String
    public let key: String
    public let representation: Representation

    public init(name: String, key: String, representation: Representation) {
        self.name = name
        self.key = key
        self.representation = representation
    }

    public init(name: String, key: String) {
        self.init(name: name, key: key, representation: .checkmark)
    }
}

public extension Array where Element == SettingCheckmarkItem {
    func toSection(header: String? = nil, footer: String? = nil) -> SettingCommonItem.Section {
        return SettingCommonItem.Section(
            header: header,
            rows: map({ item in
                return SettingItem(
                    name: item.name,
                    type: .checkmark,
                    associatedItem: item
                )
            }),
            footer: footer
        )
    }
}

public struct AssociatedSelectionItem: Hashable {
    public let key: String
    public let items: [SettingSelectionItem]

    public func toSection(header: String? = nil, footer: String? = nil) -> SettingCommonItem.Section {
        return SettingCommonItem.Section(header: header, rows: items.map { item in
            return SettingItem(
                name: item.name,
                type: .keyedSelection,
                associatedItem: SettingKeyedSelectionItem(name: item.name, key: key, index: item.index)
            )
        }, footer: footer)
    }

    public init(key: String, items: [SettingSelectionItem]) {
        self.key = key
        self.items = items
    }
}

public struct SettingPreferenceSwitchItem: Hashable {
    public let key: String
    public let defaultOn: Bool

    public init(key: String, defaultOn: Bool) {
        self.key = key
        self.defaultOn = defaultOn
    }
}

public struct SettingPreferenceSelectionItem: Hashable {
    public struct Option: Hashable {
        public let name: String
        public let value: Int

        public init(name: String, value: Int) {
            self.name = name
            self.value = value
        }
    }

    public let key: String
    public let options: [Option]
    public let defaultOption: Int

    public init(key: String, options: [Option], defaultOption: Int) {
        self.key = key
        self.options = options
        self.defaultOption = defaultOption
    }
}

public class BlockHolder<T: Sendable>: NSObject {
    public let block: @Sendable (T) -> Void

    public init(block: @escaping @Sendable (T) -> Void) {
        self.block = block
        super.init()
    }
}

public typealias AssociatedCommonItem = SettingCommonItem
public typealias AssociatedSliderItem = SettingSliderItem
public typealias AssociatedActionItem = SettingActionItem
public typealias AssociatedCheckmarkItem = SettingCheckmarkItem
public typealias AssociatedKeyedSelectionItem = SettingKeyedSelectionItem
public typealias AssociatedSelectionSingleItem = SettingSelectionSingleItem
public typealias AssociatedPreferenceSwitchItem = SettingPreferenceSwitchItem
public typealias AssociatedPreferenceSelectionItem = SettingPreferenceSelectionItem
public typealias AssociatedCustomItem = BlockHolder<AppCore>
