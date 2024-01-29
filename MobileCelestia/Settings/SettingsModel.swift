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
import CelestiaFoundation
import CelestiaUI
import Foundation

#if targetEnvironment(macCatalyst)
private let defaultSensitivity: Double = 4.0
#else
private let defaultSensitivity: Double = 10.0
#endif
private let sharedInteractionItems: [SettingItem<AnyHashable>] = [
    SettingItem(
        name: CelestiaString("Reverse Mouse Wheel", comment: ""),
        type: .checkmark,
        associatedItem: .init(
            AssociatedCheckmarkItem(name: CelestiaString("Reverse Mouse Wheel", comment: ""), key: "enableReverseWheel", representation: .switch)
        )
    ),
    SettingItem(
        name: CelestiaString("Ray-Based Dragging", comment: ""),
        subtitle: CelestiaString("Dragging behavior based on change of pick rays instead of screen coordinates", comment: ""),
        type: .checkmark,
        associatedItem: .init(
            AssociatedCheckmarkItem(name: CelestiaString("Ray-Based Dragging", comment: ""), key: "enableRayBasedDragging", representation: .switch)
        )
    ),
    SettingItem(
        name: CelestiaString("Focus Zooming", comment: ""),
        subtitle: CelestiaString("Zooming behavior keeping the original focus location on screen", comment: ""),
        type: .checkmark,
        associatedItem: .init(
            AssociatedCheckmarkItem(name: CelestiaString("Focus Zooming", comment: ""), key: "enableFocusZooming", representation: .switch)
        )
    ),
    SettingItem(
        name: CelestiaString("Sensitivity", comment: "Setting for sensitivity for selecting an object"),
        subtitle: CelestiaString("Sensitivity for object selection", comment: "Notes for the sensitivity setting"),
        type: .prefSlider,
        associatedItem: .init(
            AssociatedPreferenceSliderItem(key: .pickSensitivity, minValue: 1.0, maxValue: 20.0, defaultValue: defaultSensitivity)
        )
    )
]

#if targetEnvironment(macCatalyst)
private let interactionItems = sharedInteractionItems
#else
private let interactionItems = sharedInteractionItems + [
    SettingItem(
        name: CelestiaString("Context Menu", comment: "Settings for whether context menu is enabled"),
        subtitle: CelestiaString("Context menu by long press or context click", comment: "Description for how a context menu is triggered"),
        type: .prefSwitch,
        associatedItem: .init(
            AssociatedPreferenceSwitchItem(key: .contextMenu, defaultOn: true)
        )
    )
]
#endif

private let advanceSettingExtraItems = [
    SettingItem(
        name: CelestiaString("Interaction", comment: "Settings for interaction"),
        type: .common,
        associatedItem: .init(
            AssociatedCommonItem(
                title: CelestiaString("Interaction", comment: "Settings for interaction"),
                sections: [
                    .init(
                        header: nil,
                        rows: interactionItems,
                        footer: CelestiaString("Some configurations will take effect after a restart.", comment: "")
                    ),
                ]
            )
        )
    ),
    gameControllerItem,
]

let mainSetting: [SettingSection] = {
    var items = [
        displaySettings(),
        timeAndRegionSettings(),
        rendererSettings(extraItems: [
            SettingItem(
                name: CelestiaString("Advanced", comment: "Advanced setting items"),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Advanced", comment: "Advanced setting items"),
                        sections: [
                            .init(header: nil, rows: [
                                SettingItem(
                                    name: CelestiaString("HiDPI", comment: "HiDPI support in display"),
                                    type: .prefSwitch,
                                    associatedItem: .init(
                                        AssociatedPreferenceSwitchItem(key: .fullDPI, defaultOn: true)
                                    )
                                ),
                                SettingItem(
                                    name: CelestiaString("Anti-aliasing", comment: ""),
                                    type: .prefSwitch,
                                    associatedItem: .init(
                                        AssociatedPreferenceSwitchItem(key: .msaa, defaultOn: false)
                                    )
                                )
                            ], footer: CelestiaString("Configuration will take effect after a restart.", comment: "Change requires a restart")),
                        ]
                    )
                )
            ),
        ]),
        advancedSettings(extraItems: advanceSettingExtraItems),
    ]
    if #available(iOS 15, *) {
        items.append(celestiaPlusSettings())
    }
    items.append(miscSettings())
    return items
}()
