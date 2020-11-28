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

import Foundation

import CelestiaCore

enum SettingType: Hashable {
    case multiSelection
    case selection
    case slider
    case action
    case prefSwitch
    case common
    case about
    case render
    case time
    case dataLocation
    case checkmark
    case custom
}

struct AssociatedMultiSelectionItem: Hashable {
    let masterKey: String?
    let items: [SettingCheckmarkItem]
}

struct AssociatedSelectionItem: Hashable {
    let key: String
    let items: [SettingSelectionItem]
}

typealias AssociatedCommonItem = SettingCommonItem
typealias AssociatedSliderItem = SettingSliderItem
typealias AssociatedActionItem = SettingActionItem
typealias AssociatedPreferenceSwitchItem = SettingPreferenceSwitchItem
typealias AssociatedCheckmarkItem = SettingCheckmarkItem
typealias AssociatedCustomItem = BlockHolder<CelestiaAppCore>

class BlockHolder<T>: NSObject {
    let block: (T) -> Void

    init(block: @escaping (T) -> Void) {
        self.block = block
        super.init()
    }
}

struct SettingCheckmarkItem: Hashable {
    enum Representation: Hashable {
        case checkmark
        case `switch`
    }

    let name: String
    let key: String
    let representation: Representation

    init(name: String, key: String, representation: Representation) {
        self.name = name
        self.key = key
        self.representation = representation
    }

    init(name: String, key: String) {
        self.init(name: name, key: key, representation: .checkmark)
    }
}

struct SettingSelectionItem: Hashable {
    let name: String
    let index: Int
}

struct SettingSliderItem: Hashable {
    let key: String
    let minValue: Double
    let maxValue: Double
}

struct SettingPreferenceSwitchItem: Hashable {
    let key: UserDefaultsKey
    let defaultOn: Bool
}

struct SettingActionItem: Hashable {
    let action: Int8
}

struct SettingItem<T: Hashable>: Hashable {
    let name: String
    let type: SettingType
    let associatedItem: T
}

struct SettingSection: Hashable {
    let title: String
    let items: [SettingItem<AnyHashable>]
}

enum TextItem {
    case short(title: String, detail: String?)
    case long(content: String)
    case link(title: String, url: URL)
}

struct SettingCommonItem: Hashable {
    struct Section: Hashable {
        let rows: [SettingItem<AnyHashable>]
        let footer: String?
    }
    let title: String
    let sections: [Section]
}

extension SettingCommonItem {
    init(title: String, items: [SettingItem<AnyHashable>]) {
        self.init(title: title, sections: [Section(rows: items, footer: nil)])
    }
}

extension SettingCommonItem {
    init(item: SettingItem<AnyHashable>) {
        self.init(title: item.name, items: [item])
    }
}

let mainSetting = [
    SettingSection(
        title: CelestiaString("Display", comment: ""),
        items: [
            SettingItem(
                name: CelestiaString("Objects", comment: ""),
                type: .multiSelection,
                associatedItem: .init(
                    AssociatedMultiSelectionItem(
                        masterKey: nil,
                        items: [
                            SettingCheckmarkItem(name: CelestiaString("Stars", comment: ""), key: "showStars"),
                            SettingCheckmarkItem(name: CelestiaString("Planets", comment: ""), key: "showPlanets"),
                            SettingCheckmarkItem(name: CelestiaString("Dwarf Planets", comment: ""), key: "showDwarfPlanets"),
                            SettingCheckmarkItem(name: CelestiaString("Moons", comment: ""), key: "showMoons"),
                            SettingCheckmarkItem(name: CelestiaString("Minor Moons", comment: ""), key: "showMinorMoons"),
                            SettingCheckmarkItem(name: CelestiaString("Asteroids", comment: ""), key: "showAsteroids"),
                            SettingCheckmarkItem(name: CelestiaString("Comets", comment: ""), key: "showComets"),
                            SettingCheckmarkItem(name: CelestiaString("Spacecraft", comment: ""), key: "showSpacecrafts"),
                            SettingCheckmarkItem(name: CelestiaString("Galaxies", comment: ""), key: "showGalaxies"),
                            SettingCheckmarkItem(name: CelestiaString("Nebulae", comment: ""), key: "showNebulae"),
                            SettingCheckmarkItem(name: CelestiaString("Globulars", comment: ""), key: "showGlobulars"),
                            SettingCheckmarkItem(name: CelestiaString("Open Clusters", comment: ""), key: "showOpenClusters"),
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Features", comment: ""),
                type: .multiSelection,
                associatedItem: .init(
                    AssociatedMultiSelectionItem(
                        masterKey: nil,
                        items: [
                            SettingCheckmarkItem(name: CelestiaString("Atmospheres", comment: ""), key: "showAtmospheres"),
                            SettingCheckmarkItem(name: CelestiaString("Clouds", comment: ""), key: "showCloudMaps"),
                            SettingCheckmarkItem(name: CelestiaString("Cloud Shadows", comment: ""), key: "showCloudShadows"),
                            SettingCheckmarkItem(name: CelestiaString("Night Lights", comment: ""), key: "showNightMaps"),
                            SettingCheckmarkItem(name: CelestiaString("Planet Rings", comment: ""), key: "showPlanetRings"),
                            SettingCheckmarkItem(name: CelestiaString("Ring Shadows", comment: ""), key: "showRingShadows"),
                            SettingCheckmarkItem(name: CelestiaString("Comet Tails", comment: ""), key: "showCometTails"),
                            SettingCheckmarkItem(name: CelestiaString("Eclipse Shadows", comment: ""), key: "showEclipseShadows"),
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Orbits", comment: ""),
                type: .multiSelection,
                associatedItem: .init(
                    AssociatedMultiSelectionItem(
                        masterKey: "showOrbits",
                        items: [
                            SettingCheckmarkItem(name: CelestiaString("Stars", comment: ""), key: "showStellarOrbits"),
                            SettingCheckmarkItem(name: CelestiaString("Planets", comment: ""), key: "showPlanetOrbits"),
                            SettingCheckmarkItem(name: CelestiaString("Dwarf Planets", comment: ""), key: "showDwarfPlanetOrbits"),
                            SettingCheckmarkItem(name: CelestiaString("Moons", comment: ""), key: "showMoonOrbits"),
                            SettingCheckmarkItem(name: CelestiaString("Minor Moons", comment: ""), key: "showMinorMoonOrbits"),
                            SettingCheckmarkItem(name: CelestiaString("Asteroids", comment: ""), key: "showAsteroidOrbits"),
                            SettingCheckmarkItem(name: CelestiaString("Comets", comment: ""), key: "showCometOrbits"),
                            SettingCheckmarkItem(name: CelestiaString("Spacecraft", comment: ""), key: "showSpacecraftOrbits"),
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Grids", comment: ""),
                type: .multiSelection,
                associatedItem: .init(
                    AssociatedMultiSelectionItem(
                        masterKey: nil,
                        items: [
                            SettingCheckmarkItem(name: CelestiaString("Equatorial", comment: ""), key: "showCelestialSphere"),
                            SettingCheckmarkItem(name: CelestiaString("Ecliptic", comment: ""), key: "showEclipticGrid"),
                            SettingCheckmarkItem(name: CelestiaString("Horizontal", comment: ""), key: "showHorizonGrid"),
                            SettingCheckmarkItem(name: CelestiaString("Galactic", comment: ""), key: "showGalacticGrid"),
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Constellations", comment: ""),
                type: .multiSelection,
                associatedItem: .init(
                    AssociatedMultiSelectionItem(
                        masterKey: "showDiagrams",
                        items: [
                            SettingCheckmarkItem(name: CelestiaString("Constellation Labels", comment: ""), key: "showConstellationLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Constellations in Latin", comment: ""), key: "showLatinConstellationLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Show Boundaries", comment: ""), key: "showBoundaries"),
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Object Labels", comment: ""),
                type: .multiSelection,
                associatedItem: .init(
                    AssociatedMultiSelectionItem(
                        masterKey: nil,
                        items: [
                            SettingCheckmarkItem(name: CelestiaString("Stars", comment: ""), key: "showStarLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Planets", comment: ""), key: "showPlanetLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Dwarf Planets", comment: ""), key: "showDwarfPlanetLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Moons", comment: ""), key: "showMoonLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Minor Moons", comment: ""), key: "showMinorMoonLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Asteroids", comment: ""), key: "showAsteroidLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Comets", comment: ""), key: "showCometLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Spacecraft", comment: ""), key: "showSpacecraftLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Galaxies", comment: ""), key: "showGalaxyLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Nebulae", comment: ""), key: "showNebulaLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Globulars", comment: ""), key: "showGlobularLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Open Clusters", comment: ""), key: "showOpenClusterLabels"),
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Locations", comment: ""),
                type: .multiSelection,
                associatedItem: .init(
                    AssociatedMultiSelectionItem(
                        masterKey: "showLocationLabels",
                        items: [
                            SettingCheckmarkItem(name: CelestiaString("Cities", comment: ""), key: "showCityLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Observatories", comment: ""), key: "showObservatoryLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Landing Sites", comment: ""), key: "showLandingSiteLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Mons", comment: ""), key: "showMonsLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Mare", comment: ""), key: "showMareLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Crater", comment: ""), key: "showCraterLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Vallis", comment: ""), key: "showVallisLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Terra", comment: ""), key: "showTerraLabels"),
                            SettingCheckmarkItem(name: CelestiaString("Volcanoes", comment: ""), key: "showEruptiveCenterLabels"),
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Markers", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Markers", comment: ""),
                        sections: [
                            .init(rows: [
                                SettingItem(
                                    name: CelestiaString("Show Markers", comment: ""),
                                    type: .checkmark,
                                    associatedItem: .init(
                                        SettingCheckmarkItem(name: CelestiaString("Show Markers", comment: ""), key: "showMarkers", representation: .switch)
                                    )
                                ),
                                SettingItem(
                                    name: CelestiaString("Unmark All", comment: ""),
                                    type: .custom,
                                    associatedItem: .init(
                                        AssociatedCustomItem(){ core in
                                            core.simulation.universe.unmarkAll()
                                        }
                                    )
                                )
                            ], footer: nil)
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Reference Vectors", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Reference Vectors", comment: ""),
                        sections: [
                            .init(rows: [
                                AssociatedCheckmarkItem(name: CelestiaString("Show Body Axes", comment: ""), key: "showBodyAxes"),
                                AssociatedCheckmarkItem(name: CelestiaString("Show Frame Axes", comment: ""), key: "showFrameAxes"),
                                AssociatedCheckmarkItem(name: CelestiaString("Show Sun Direction", comment: ""), key: "showSunDirection"),
                                AssociatedCheckmarkItem(name: CelestiaString("Show Velocity Vector", comment: ""), key: "showVelocityVector"),
                                AssociatedCheckmarkItem(name: CelestiaString("Show Planetographic Grid", comment: ""), key: "showPlanetographicGrid"),
                                AssociatedCheckmarkItem(name: CelestiaString("Show Terminator", comment: ""), key: "showTerminator"),
                            ].map { (item) -> SettingItem<AnyHashable> in
                                return .init(name: item.name, type: .checkmark, associatedItem: .init(item))
                            }, footer: CelestiaString("Reference vectors are only visible for the current selected solar system object.", comment: ""))
                        ]
                    )
                )
            )
        ]),
    SettingSection(
        title: CelestiaString("Time", comment: ""),
        items: [
            SettingItem(
                name: CelestiaString("Time Zone", comment: ""),
                type: .selection,
                associatedItem: .init(
                    AssociatedSelectionItem(
                        key: "timeZone",
                        items: [
                            SettingSelectionItem(name: CelestiaString("Local Time", comment: ""), index: 0),
                            SettingSelectionItem(name: CelestiaString("UTC", comment: ""), index: 1),
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Date Format", comment: ""),
                type: .selection,
                associatedItem: .init(
                    AssociatedSelectionItem(
                        key: "dateFormat",
                        items: [
                            SettingSelectionItem(name: CelestiaString("Default", comment: ""), index: 0),
                            SettingSelectionItem(name: CelestiaString("YYYY MMM DD HH:MM:SS TZ", comment: ""), index: 1),
                            SettingSelectionItem(name: CelestiaString("UTC Offset", comment: ""), index: 2),
                        ]
                    )
                )
            ),
            SettingItem(name: CelestiaString("Current Time", comment: ""), type: .time, associatedItem: .init(0))
        ]),
    SettingSection(
        title: CelestiaString("Advanced", comment: ""),
        items: [
            SettingItem(
                name: CelestiaString("Texture Resolution", comment: ""),
                type: .selection,
                associatedItem: .init(
                    AssociatedSelectionItem(
                        key: "resolution",
                        items: [
                            SettingSelectionItem(name: CelestiaString("Low", comment: ""), index: 0),
                            SettingSelectionItem(name: CelestiaString("Medium", comment: ""), index: 1),
                            SettingSelectionItem(name: CelestiaString("High", comment: ""), index: 2),
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Star Style", comment: ""),
                type: .selection,
                associatedItem: .init(
                    AssociatedSelectionItem(
                        key: "starStyle", items: [
                            SettingSelectionItem(name: CelestiaString("Fuzzy Points", comment: ""), index: 0),
                            SettingSelectionItem(name: CelestiaString("Points", comment: ""), index: 1),
                            SettingSelectionItem(name: CelestiaString("Scaled Discs", comment: ""), index: 2),
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Info Display", comment: ""),
                type: .selection,
                associatedItem: .init(
                    AssociatedSelectionItem(
                        key: "hudDetail", items: [
                            SettingSelectionItem(name: CelestiaString("None", comment: ""), index: 0),
                            SettingSelectionItem(name: CelestiaString("Terse", comment: ""), index: 1),
                            SettingSelectionItem(name: CelestiaString("Verbose", comment: ""), index: 2),
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Render Parameters", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Render Parameters", comment: ""),
                        sections: [
                            .init(rows: [
                                SettingItem(
                                    name: CelestiaString("Ambient Light", comment: ""),
                                    type: .slider,
                                    associatedItem: .init(
                                        AssociatedSliderItem(key: "ambientLightLevel", minValue: 0, maxValue: 1)
                                    )
                                ),
                                SettingItem(
                                    name: CelestiaString("Faintest Stars", comment: ""),
                                    type: .slider,
                                    associatedItem: .init(
                                        AssociatedSliderItem(key: "faintestVisible", minValue: 3, maxValue: 12)
                                    )
                                ),
                                SettingItem(
                                    name: CelestiaString("Minimum Labelled Feature Size", comment: ""),
                                    type: .slider,
                                    associatedItem: .init(
                                        AssociatedSliderItem(key: "minimumFeatureSize", minValue: 0, maxValue: 99)
                                    )
                                ),
                                SettingItem(
                                    name: CelestiaString("Galaxy Brightness", comment: ""),
                                    type: .slider,
                                    associatedItem: .init(
                                        AssociatedSliderItem(key: "galaxyBrightness", minValue: 0, maxValue: 1)
                                    )
                                ),
                            ], footer: nil),
                            .init(rows: [
                                SettingItem(
                                    name: CelestiaString("HiDPI", comment: ""),
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
                                ),
                            ], footer: CelestiaString("Configuration will take effect after a restart.", comment: "")),
                        ]
                    )
                )
            ),
            SettingItem(name: CelestiaString("Data Location", comment: ""), type: .dataLocation, associatedItem: .init(0)),
        ]),
    SettingSection(
        title: CelestiaString("Others", comment: ""),
        items: [
            SettingItem(name: CelestiaString("Render Info", comment: ""), type: .render, associatedItem: .init(0)),
            SettingItem(
                name: CelestiaString("Debug", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Debug", comment: ""),
                        items: [
                            SettingItem(
                                name: CelestiaString("Toggle FPS Display", comment: ""),
                                type: .action,
                                associatedItem: .init(
                                    AssociatedActionItem(action: 0x60)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Toggle Console Display", comment: ""),
                                type: .action,
                                associatedItem: .init(
                                    AssociatedActionItem(action: 0x7E)
                                )
                            )
                        ]
                    )
                )
            ),
            SettingItem(name: CelestiaString("About", comment: ""), type: .about, associatedItem: .init(0))

    ])
]
