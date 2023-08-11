//
// SettingModel.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import CelestiaUI
import Foundation

extension SettingPreferenceSwitchItem {
    init(userDefaultsKey: UserDefaultsKey, defaultOn: Bool) {
        self.init(key: userDefaultsKey.rawValue, defaultOn: defaultOn)
    }
}

extension SettingPreferenceSelectionItem {
    init(userDefaultsKey: UserDefaultsKey, options: [Option], defaultOption: Int) {
        self.init(key: userDefaultsKey.rawValue, options: options, defaultOption: defaultOption)
    }
}

private let gamepadActions = GameControllerAction.allCases.map { action in
    SettingPreferenceSelectionItem.Option(name: action.name, value: action.rawValue)
}

private let gameControllerItem = SettingItem<AnyHashable>(
    name: CelestiaString("Game Controller", comment: ""),
    type: .common,
    associatedItem: .init(
        AssociatedCommonItem(
            title: CelestiaString("Game Controller", comment: ""),
            sections: [
                .init(header: CelestiaString("Buttons", comment: ""), rows: [
                    SettingItem(
                        name: CelestiaString("A / X", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapA, options: gamepadActions, defaultOption: GameControllerAction.moveSlower.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("B / Circle", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapB, options: gamepadActions, defaultOption: GameControllerAction.noop.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("X / Square", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapX, options: gamepadActions, defaultOption: GameControllerAction.moveFaster.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("Y / Triangle", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapY, options: gamepadActions, defaultOption: GameControllerAction.noop.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("LB / L1", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapLB, options: gamepadActions, defaultOption: GameControllerAction.noop.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("LT / L2", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapLT, options: gamepadActions, defaultOption: GameControllerAction.rollLeft.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("RB / R1", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapRB, options: gamepadActions, defaultOption: GameControllerAction.noop.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("RT / R2", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapRT, options: gamepadActions, defaultOption: GameControllerAction.rollRight.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("D-pad Up", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapDpadUp, options: gamepadActions, defaultOption: GameControllerAction.pitchUp.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("D-pad Down", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapDpadDown, options: gamepadActions, defaultOption: GameControllerAction.pitchDown.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("D-pad Left", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapDpadLeft, options: gamepadActions, defaultOption: GameControllerAction.rollLeft.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("D-pad Right", comment: ""),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(userDefaultsKey: .gameControllerRemapDpadRight, options: gamepadActions, defaultOption: GameControllerAction.rollRight.rawValue)
                        )
                    ),
                ], footer: nil),
                .init(header: CelestiaString("Thumbsticks", comment: ""), rows: [
                    SettingItem(
                        name: CelestiaString("Invert Horizontally", comment: ""),
                        type: .prefSwitch,
                        associatedItem: .init(
                            AssociatedPreferenceSwitchItem(userDefaultsKey: .gameControllerInvertX, defaultOn: false)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("Invert Vertically", comment: ""),
                        type: .prefSwitch,
                        associatedItem: .init(
                            AssociatedPreferenceSwitchItem(userDefaultsKey: .gameControllerInvertY, defaultOn: false)
                        )
                    ),
                ], footer: nil),
            ]
        )
    )
)

#if targetEnvironment(macCatalyst)
private let advanceSettingExtraItems = [gameControllerItem]
#else
private let advanceSettingExtraItems = [
    SettingItem(
        name: CelestiaString("Interaction", comment: ""),
        type: .common,
        associatedItem: .init(
            AssociatedCommonItem(
                title: CelestiaString("Interaction", comment: ""),
                sections: [
                    .init(
                        header: nil,
                        rows: [
                        SettingItem(
                            name: CelestiaString("Context Menu", comment: ""),
                            subtitle: CelestiaString("Long press or context click triggers context menu display", comment: ""),
                            type: .prefSwitch,
                            associatedItem: .init(
                                AssociatedPreferenceSwitchItem(userDefaultsKey: .contextMenu, defaultOn: true)
                            )
                        ),
                    ], footer: CelestiaString("Configuration will take effect after a restart.", comment: "")),
                ]
            )
        )
    ),
    gameControllerItem,
]
#endif

let mainSetting = [
    displaySettings(),
    timeAndRegionSettings(),
    rendererSettings(extraItems: [
        SettingItem(
            name: CelestiaString("Advanced", comment: ""),
            type: .common,
            associatedItem: .init(
                AssociatedCommonItem(
                    title: CelestiaString("Advanced", comment: ""),
                    sections: [
                        .init(header: nil, rows: [
                            SettingItem(
                                name: CelestiaString("HiDPI", comment: ""),
                                type: .prefSwitch,
                                associatedItem: .init(
                                    AssociatedPreferenceSwitchItem(userDefaultsKey: .fullDPI, defaultOn: true)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Anti-aliasing", comment: ""),
                                type: .prefSwitch,
                                associatedItem: .init(
                                    AssociatedPreferenceSwitchItem(userDefaultsKey: .msaa, defaultOn: false)
                                )
                            )
                        ], footer: CelestiaString("Configuration will take effect after a restart.", comment: "")),
                    ]
                )
            )
        ),
    ]),
    advancedSettings(extraItems: advanceSettingExtraItems),
    miscSettings()
]
