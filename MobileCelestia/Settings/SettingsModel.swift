// SettingsModel.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaFoundation
import CelestiaUI
import Foundation

#if targetEnvironment(macCatalyst)
private let defaultSensitivity: Double = 4.0
#else
private let defaultSensitivity: Double = 10.0
#endif
private let sharedInteractionItems: [SettingItem] = [
    SettingItem(
        name: CelestiaString("Reverse Mouse Wheel", comment: ""),
        associatedItem: .checkmark(item:
            AssociatedCheckmarkItem(name: CelestiaString("Reverse Mouse Wheel", comment: ""), key: "enableReverseWheel", representation: .switch)
        )
    ),
    SettingItem(
        name: CelestiaString("Ray-Based Dragging", comment: ""),
        subtitle: CelestiaString("Dragging behavior based on change of pick rays instead of screen coordinates", comment: ""),
        associatedItem: .checkmark(item:
            AssociatedCheckmarkItem(name: CelestiaString("Ray-Based Dragging", comment: ""), key: "enableRayBasedDragging", representation: .switch)
        )
    ),
    SettingItem(
        name: CelestiaString("Focus Zooming", comment: ""),
        subtitle: CelestiaString("Zooming behavior keeping the original focus location on screen", comment: ""),
        associatedItem: .checkmark(item:
            AssociatedCheckmarkItem(name: CelestiaString("Focus Zooming", comment: ""), key: "enableFocusZooming", representation: .switch)
        )
    ),
    SettingItem(
        name: CelestiaString("Sensitivity", comment: "Setting for sensitivity for selecting an object"),
        subtitle: CelestiaString("Sensitivity for object selection", comment: "Notes for the sensitivity setting"),
        associatedItem: .prefSlider(item:
            AssociatedPreferenceSliderItem(key: .pickSensitivity, minValue: 1.0, maxValue: 20.0, defaultValue: defaultSensitivity)
        )
    )
]

#if targetEnvironment(macCatalyst)
private let interactionItems = sharedInteractionItems + [
    SettingItem(
        name: CelestiaString("Pinch Zoom", comment: "Settings for whether to pinch to zoom by FOV or by distance"),
        subtitle: CelestiaString("Adjust view with pinch gestures by changing FOV or distance", comment: "Description for Pinch Zoom setting"),
        associatedItem: .prefSelection(item:
            AssociatedPreferenceSelectionItem(key: .pinchZoom, options: [
                .init(name: CelestiaString("FOV", context: "Pinch Zoom", comment: "Pinch zoom setting option"), value: 0),
                .init(name: CelestiaString("Distance", context: "Pinch Zoom", comment: "Pinch zoom setting option"), value: 1)
            ], defaultOption: 0)
        )
    )
]
#else
private let interactionItems = sharedInteractionItems + [
    SettingItem(
        name: CelestiaString("Context Menu", comment: "Settings for whether context menu is enabled"),
        subtitle: CelestiaString("Context menu by long press or context click", comment: "Description for how a context menu is triggered"),
        associatedItem: .prefSwitch(item:
            AssociatedPreferenceSwitchItem(key: .contextMenu, defaultOn: true)
        )
    )
]
#endif

private let advanceSettingExtraItems = [
    SettingItem(
        name: CelestiaString("Interaction", comment: "Settings for interaction"),
        associatedItem: .common(item:
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
    SettingItem(
        name: CelestiaString("Camera", comment: "Settings for camera control"),
        associatedItem: .common(item:
            AssociatedCommonItem(
                title: CelestiaString("Camera", comment: "Settings for camera control"),
                sections: [
                    .init(
                        header: nil,
                        rows: [
                            SettingItem(
                                name: CelestiaString("Align to Surface on Landing", comment: "Option to align camera to surface when landing"),
                                associatedItem: .checkmark(item:
                                    AssociatedCheckmarkItem(name: CelestiaString("Align to Surface on Landing", comment: "Option to align camera to surface when landing"), key: "enableAlignCameraToSurfaceOnLand", representation: .switch)
                                )
                            ),
                        ],
                        footer: nil
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
                associatedItem: .common(item:
                    AssociatedCommonItem(
                        title: CelestiaString("Advanced", comment: "Advanced setting items"),
                        sections: [
                            .init(header: nil, rows: [
                                SettingItem(
                                    name: CelestiaString("HiDPI", comment: "HiDPI support in display"),
                                    associatedItem: .prefSwitch(item:
                                        AssociatedPreferenceSwitchItem(key: .fullDPI, defaultOn: true)
                                    )
                                ),
                                SettingItem(
                                    name: CelestiaString("Anti-aliasing", comment: ""),
                                    associatedItem: .prefSwitch(item:
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
    items.append(celestiaPlusSettings())
    items.append(miscSettings())
    return items
}()
