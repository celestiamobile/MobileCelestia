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

private let shadowMapSizeFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    return formatter
}()

private let shadowMapSizeOptions: [AssociatedPreferenceSelectionItem.Option] = [0, 1024, 2048, 4096, 8192].map { size in
    .init(name: shadowMapSizeFormatter.string(from: size), value: size)
}

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
        name: CelestiaString("Hide Cursor During Dragging", comment: ""),
        subtitle: CelestiaString("Hide the mouse cursor during dragging", comment: ""),
        associatedItem: .prefSwitch(
            item: AssociatedPreferenceSwitchItem(key: .hideCursorDuringDragging, defaultOn: true)
        )
    ),
    SettingItem(
        name: CelestiaString("Infinite Dragging", comment: ""),
        subtitle: CelestiaString("Mouse cursor is warped to the location when the dragging starts. Only effective when the cursor is hidden during dragging", comment: ""),
        associatedItem: .prefSwitch(
            item: AssociatedPreferenceSwitchItem(key: .infiniteDragging, defaultOn: true)
        )
    ),
    SettingItem(
        name: CelestiaString("Pinch Zoom", comment: "Settings for whether to pinch to zoom by FOV or by distance"),
        subtitle: CelestiaString("Adjust view with pinch gestures by changing FOV or distance", comment: "Description for Pinch Zoom setting"),
        associatedItem: .prefSelection(item:
            AssociatedPreferenceSelectionItem(key: .pinchZoom, options: [
                .init(name: CelestiaString("FOV", context: "Pinch Zoom", comment: "Pinch zoom setting option"), value: 0),
                .init(name: CelestiaString("Distance", context: "Pinch Zoom", comment: "Pinch zoom setting option"), value: 1)
            ], defaultOption: 0)
        )
    ),
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

@MainActor
let notificationsSettingSection: SettingSection = SettingSection(
    title: nil,
    items: [
        SettingItem(
            name: CelestiaString("Notifications", comment: "Push notification settings entry"),
            associatedItem: .other(type: .notifications)
        )
    ]
)

@MainActor
func mainSetting(featureFlags: FeatureFlags) -> [SettingSection] {
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
                                ),
                                SettingItem(
                                    name: CelestiaString("Shadow Resolution", comment: "Resolution of shadow maps"),
                                    subtitle: CelestiaString("A value of 0 disables self-shadowing. Higher values produce sharper shadows at a greater performance cost.", comment: "Shadow resolution setting footnote"),
                                    associatedItem: .prefSelection(
                                        item: AssociatedPreferenceSelectionItem(key: .shadowMapSize, options: shadowMapSizeOptions, defaultOption: 0)
                                    )
                                ),
                            ], footer: CelestiaString("Configuration will take effect after a restart.", comment: "Change requires a restart")),
                            .init(header: CelestiaString("Output Rendering", comment: "Output rendering settings"), rows: [
                                SettingItem(
                                    name: CelestiaString("sRGB Rendering (Experimental)", comment: ""),
                                    associatedItem: .prefSwitch(
                                        item: AssociatedPreferenceSwitchItem(key: .srgbRendering, defaultOn: false)
                                    )
                                ),
                                SettingItem(
                                    name: CelestiaString("Tone Mapping", comment: "Tone mapping setting"),
                                    associatedItem: .selection(
                                        item: AssociatedSelectionSingleItem(
                                            key: "toneMapping",
                                            options: [
                                                .init(name: CelestiaString("Off", comment: "Tone mapping mode"), value: 0),
                                                .init(name: CelestiaString("Manual", comment: "Tone mapping mode"), value: 1),
                                            ],
                                            defaultOption: 0
                                        )
                                    )
                                ),
                                SettingItem(
                                    name: CelestiaString("Exposure", comment: "Output rendering setting"),
                                    associatedItem: .slider(
                                        item: AssociatedSliderItem(
                                            key: "exposure",
                                            minValue: 0.01,
                                            maxValue: 100,
                                            isLogarithmic: true
                                        )
                                    )
                                ),
                            ], footer: CelestiaString("Tone mapping and exposure only affect sRGB rendering. Changes to sRGB rendering take effect after a restart.", comment: "Output rendering settings footnote")),
                        ]
                    )
                )
            ),
        ]),
        advancedSettings(extraItems: advanceSettingExtraItems),
    ]
    #if !targetEnvironment(macCatalyst)
    items.append(notificationsSettingSection)
    #endif
    #if APPSTORE_BUILD
    items.append(celestiaPlusSettings())
    #endif
    items.append(miscSettings())
    return items
}
