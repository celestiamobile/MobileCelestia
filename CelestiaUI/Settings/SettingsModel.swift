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
import CelestiaFoundation
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
    #if !os(visionOS)
    case frameRate
    #endif
    case checkmark
    case custom
    case keyedSelection
    case prefSelection
    case selection
    case prefSlider
    #if !os(visionOS)
    case font
    case toolbar
    #endif
}

public struct SettingItem<T: Hashable>: Hashable {
    public let name: String
    public let subtitle: String?
    public let type: SettingType
    public let associatedItem: T

    public init(name: String, subtitle: String? = nil, type: SettingType, associatedItem: T) {
        self.name = name
        self.subtitle = subtitle
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
    case action(title: String)
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
    public let subtitle: String?
    public let items: [SettingSelectionItem]

    public func toSection(header: String? = nil, footer: String? = nil) -> SettingCommonItem.Section {
        return SettingCommonItem.Section(header: header, rows: items.map { item in
            return SettingItem(
                name: item.name,
                subtitle: subtitle,
                type: .keyedSelection,
                associatedItem: SettingKeyedSelectionItem(name: item.name, key: key, index: item.index)
            )
        }, footer: footer)
    }

    public init(key: String, subtitle: String? = nil, items: [SettingSelectionItem]) {
        self.key = key
        self.subtitle = subtitle
        self.items = items
    }
}

public struct SettingPreferenceSwitchItem: Hashable {
    public let key: UserDefaultsKey
    public let defaultOn: Bool

    public init(key: UserDefaultsKey, defaultOn: Bool) {
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

    public let key: UserDefaultsKey
    public let options: [Option]
    public let defaultOption: Int

    public init(key: UserDefaultsKey, options: [Option], defaultOption: Int) {
        self.key = key
        self.options = options
        self.defaultOption = defaultOption
    }
}

public struct SettingPreferenceSliderItem: Hashable {
    public let key: UserDefaultsKey
    public let minValue: Double
    public let maxValue: Double
    public let defaultValue: Double

    public init(key: UserDefaultsKey, minValue: Double, maxValue: Double, defaultValue: Double) {
        self.key = key
        self.minValue = minValue
        self.maxValue = maxValue
        self.defaultValue = defaultValue
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
public typealias AssociatedPreferenceSliderItem = SettingPreferenceSliderItem
public typealias AssociatedCustomItem = BlockHolder<AppCore>

public func displaySettings() -> SettingSection {
    return SettingSection(
        title: CelestiaString("Display", comment: "Display settings"),
        items: [
            SettingItem(
                name: CelestiaString("Objects", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Objects", comment: ""),
                        sections: [
                            [
                                SettingCheckmarkItem(name: CelestiaString("Stars", comment: "Tab for stars in Star Browser"), key: "showStars"),
                                SettingCheckmarkItem(name: CelestiaString("Planets", comment: ""), key: "showPlanets"),
                                SettingCheckmarkItem(name: CelestiaString("Dwarf Planets", comment: ""), key: "showDwarfPlanets"),
                                SettingCheckmarkItem(name: CelestiaString("Moons", comment: ""), key: "showMoons"),
                                SettingCheckmarkItem(name: CelestiaString("Minor Moons", comment: ""), key: "showMinorMoons"),
                                SettingCheckmarkItem(name: CelestiaString("Asteroids", comment: ""), key: "showAsteroids"),
                                SettingCheckmarkItem(name: CelestiaString("Comets", comment: ""), key: "showComets"),
                                SettingCheckmarkItem(name: CelestiaString("Spacecraft", comment: "Plural"), key: "showSpacecrafts"),
                                SettingCheckmarkItem(name: CelestiaString("Galaxies", comment: ""), key: "showGalaxies"),
                                SettingCheckmarkItem(name: CelestiaString("Nebulae", comment: ""), key: "showNebulae"),
                                SettingCheckmarkItem(name: CelestiaString("Globulars", comment: ""), key: "showGlobulars"),
                                SettingCheckmarkItem(name: CelestiaString("Open Clusters", comment: ""), key: "showOpenClusters"),
                            ].toSection()
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Features", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Features", comment: ""),
                        sections: [
                            [
                                SettingCheckmarkItem(name: CelestiaString("Atmospheres", comment: ""), key: "showAtmospheres"),
                                SettingCheckmarkItem(name: CelestiaString("Clouds", comment: ""), key: "showCloudMaps"),
                                SettingCheckmarkItem(name: CelestiaString("Cloud Shadows", comment: ""), key: "showCloudShadows"),
                                SettingCheckmarkItem(name: CelestiaString("Night Lights", comment: ""), key: "showNightMaps"),
                                SettingCheckmarkItem(name: CelestiaString("Planet Rings", comment: ""), key: "showPlanetRings"),
                                SettingCheckmarkItem(name: CelestiaString("Ring Shadows", comment: ""), key: "showRingShadows"),
                                SettingCheckmarkItem(name: CelestiaString("Comet Tails", comment: ""), key: "showCometTails"),
                                SettingCheckmarkItem(name: CelestiaString("Eclipse Shadows", comment: ""), key: "showEclipseShadows"),
                            ].toSection()
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Orbits", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(title: CelestiaString("Orbits", comment: ""), sections: [
                        .init(
                            header: nil,
                            rows: [
                            SettingItem(
                                name: CelestiaString("Show Orbits", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Show Orbits", comment: ""), key: "showOrbits", representation: .switch)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Fading Orbits", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Fading Orbits", comment: ""), key: "showFadingOrbits", representation: .switch)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Partial Trajectories", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Partial Trajectories", comment: ""), key: "showPartialTrajectories", representation: .switch)
                                )
                            ),
                        ], footer: nil),
                        .init(
                            header: nil,
                            rows: [
                            SettingItem(
                                name: CelestiaString("Stars", comment: "Tab for stars in Star Browser"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Stars", comment: "Tab for stars in Star Browser"), key: "showStellarOrbits", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Planets", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Planets", comment: ""), key: "showPlanetOrbits", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Dwarf Planets", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Dwarf Planets", comment: ""), key: "showDwarfPlanetOrbits", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Moons", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Moons", comment: ""), key: "showMoonOrbits", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Minor Moons", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Minor Moons", comment: ""), key: "showMinorMoonOrbits", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Asteroids", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Asteroids", comment: ""), key: "showAsteroidOrbits", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Comets", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Comets", comment: ""), key: "showCometOrbits", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Spacecraft", comment: "Plural"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Spacecraft", comment: "Plural"), key: "showSpacecraftOrbits", representation: .checkmark)
                                )
                            ),
                        ], footer: nil),
                    ])
                )
            ),
            SettingItem(
                name: CelestiaString("Grids", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(title: CelestiaString("Grids", comment: ""), sections: [
                        .init(
                            header: nil,
                            rows: [
                            SettingItem(
                                name: CelestiaString("Equatorial", comment: "Grids"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Equatorial", comment: "Grids"), key: "showCelestialSphere", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Ecliptic", comment: "Grids"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Ecliptic", comment: "Grids"), key: "showEclipticGrid", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Horizontal", comment: "Grids"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Horizontal", comment: "Grids"), key: "showHorizonGrid", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Galactic", comment: "Grids"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Galactic", comment: "Grids"), key: "showGalacticGrid", representation: .checkmark)
                                )
                            ),
                        ], footer: nil),
                        .init(
                            header: nil,
                            rows: [
                            SettingItem(
                                name: CelestiaString("Ecliptic Line", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Ecliptic Line", comment: ""), key: "showEcliptic", representation: .checkmark)
                                )
                            ),
                        ], footer: nil)
                    ])
                )
            ),
            SettingItem(
                name: CelestiaString("Constellations", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(title: CelestiaString("Constellations", comment: ""), items: [
                        SettingItem(
                            name: CelestiaString("Show Diagrams", comment: "Show constellation diagrams"),
                            type: .checkmark,
                            associatedItem: .init(
                                SettingCheckmarkItem(name: CelestiaString("Show Diagrams", comment: "Show constellation diagrams"), key: "showDiagrams", representation: .checkmark)
                            )
                        ),
                        SettingItem(
                            name: CelestiaString("Show Labels", comment: "Constellation labels"),
                            type: .checkmark,
                            associatedItem: .init(
                                SettingCheckmarkItem(name: CelestiaString("Show Labels", comment: "Constellation labels"), key: "showConstellationLabels", representation: .checkmark)
                            )
                        ),
                        SettingItem(
                            name: CelestiaString("Show Labels in Latin", comment: "Constellation labels in Latin"),
                            type: .checkmark,
                            associatedItem: .init(
                                SettingCheckmarkItem(name: CelestiaString("Show Labels in Latin", comment: "Constellation labels in Latin"), key: "showLatinConstellationLabels", representation: .checkmark)
                            )
                        ),
                        SettingItem(
                            name: CelestiaString("Show Boundaries", comment: "Show constellation boundaries"),
                            type: .checkmark,
                            associatedItem: .init(
                                SettingCheckmarkItem(name: CelestiaString("Show Boundaries", comment: "Show constellation boundaries"), key: "showBoundaries", representation: .checkmark)
                            )
                        ),
                    ])
                )
            ),
            SettingItem(
                name: CelestiaString("Object Labels", comment: "Labels"),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Object Labels", comment: "Labels"),
                        sections: [
                            [
                                SettingCheckmarkItem(name: CelestiaString("Stars", comment: "Tab for stars in Star Browser"), key: "showStarLabels"),
                                SettingCheckmarkItem(name: CelestiaString("Planets", comment: ""), key: "showPlanetLabels"),
                                SettingCheckmarkItem(name: CelestiaString("Dwarf Planets", comment: ""), key: "showDwarfPlanetLabels"),
                                SettingCheckmarkItem(name: CelestiaString("Moons", comment: ""), key: "showMoonLabels"),
                                SettingCheckmarkItem(name: CelestiaString("Minor Moons", comment: ""), key: "showMinorMoonLabels"),
                                SettingCheckmarkItem(name: CelestiaString("Asteroids", comment: ""), key: "showAsteroidLabels"),
                                SettingCheckmarkItem(name: CelestiaString("Comets", comment: ""), key: "showCometLabels"),
                                SettingCheckmarkItem(name: CelestiaString("Spacecraft", comment: "Plural"), key: "showSpacecraftLabels"),
                                SettingCheckmarkItem(name: CelestiaString("Galaxies", comment: ""), key: "showGalaxyLabels"),
                                SettingCheckmarkItem(name: CelestiaString("Nebulae", comment: ""), key: "showNebulaLabels"),
                                SettingCheckmarkItem(name: CelestiaString("Globulars", comment: ""), key: "showGlobularLabels"),
                                SettingCheckmarkItem(name: CelestiaString("Open Clusters", comment: ""), key: "showOpenClusterLabels"),
                            ].toSection()
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Locations", comment: "Location labels to display"),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(title: CelestiaString("Locations", comment: "Location labels to display"), sections: [
                        .init(
                            header: nil,
                            rows: [
                            SettingItem(
                                name: CelestiaString("Show Locations", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Show Locations", comment: ""), key: "showLocationLabels", representation: .switch)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Minimum Labeled Feature Size", comment: "Minimum feature size that we should display a label for"),
                                type: .slider,
                                associatedItem: .init(
                                    AssociatedSliderItem(key: "minimumFeatureSize", minValue: 0, maxValue: 99)
                                )
                            ),
                        ], footer: nil),
                        .init(
                            header: nil,
                            rows: [
                            SettingItem(
                                name: CelestiaString("Cities", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Cities", comment: ""), key: "showCityLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Observatories", comment: "Location labels"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Observatories", comment: "Location labels"), key: "showObservatoryLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Landing Sites", comment: "Location labels"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Landing Sites", comment: "Location labels"), key: "showLandingSiteLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Montes (Mountains)", comment: "Location labels"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Montes (Mountains)", comment: "Location labels"), key: "showMonsLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Maria (Seas)", comment: "Location labels"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Maria (Seas)", comment: "Location labels"), key: "showMareLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Craters", comment: "Location labels"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Craters", comment: "Location labels"), key: "showCraterLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Valles (Valleys)", comment: "Location labels"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Valles (Valleys)", comment: "Location labels"), key: "showVallisLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Terrae (Land masses)", comment: "Location labels"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Terrae (Land masses)", comment: "Location labels"), key: "showTerraLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Volcanoes", comment: "Location labels"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Volcanoes", comment: "Location labels"), key: "showEruptiveCenterLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Other", comment: "Other location labels; Android/iOS, Other objects to choose from in Eclipse Finder"),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Other", comment: "Other location labels; Android/iOS, Other objects to choose from in Eclipse Finder"), key: "showOtherLabels", representation: .checkmark)
                                )
                            ),
                        ], footer: nil)
                    ])
                )
            ),
            SettingItem(
                name: CelestiaString("Markers", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Markers", comment: ""),
                        sections: [
                            .init(
                                header: nil,
                                rows: [
                                SettingItem(
                                    name: CelestiaString("Show Markers", comment: ""),
                                    type: .checkmark,
                                    associatedItem: .init(
                                        SettingCheckmarkItem(name: CelestiaString("Show Markers", comment: ""), key: "showMarkers", representation: .switch)
                                    )
                                ),
                                SettingItem(
                                    name: CelestiaString("Unmark All", comment: "Unmark all objects"),
                                    type: .custom,
                                    associatedItem: .init(
                                        AssociatedCustomItem() { core in
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
                name: CelestiaString("Reference Vectors", comment: "Reference vectors for an object"),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Reference Vectors", comment: "Reference vectors for an object"),
                        sections: [
                            .init(header: nil, rows: [
                                AssociatedCheckmarkItem(name: CelestiaString("Show Body Axes", comment: "Reference vector"), key: "showBodyAxes"),
                                AssociatedCheckmarkItem(name: CelestiaString("Show Frame Axes", comment: "Reference vector"), key: "showFrameAxes"),
                                AssociatedCheckmarkItem(name: CelestiaString("Show Sun Direction", comment: "Reference vector"), key: "showSunDirection"),
                                AssociatedCheckmarkItem(name: CelestiaString("Show Velocity Vector", comment: "Reference vector"), key: "showVelocityVector"),
                                AssociatedCheckmarkItem(name: CelestiaString("Show Planetographic Grid", comment: "Reference vector"), key: "showPlanetographicGrid"),
                                AssociatedCheckmarkItem(name: CelestiaString("Show Terminator", comment: "Reference vector"), key: "showTerminator"),
                            ].map { (item) -> SettingItem<AnyHashable> in
                                return .init(name: item.name, type: .checkmark, associatedItem: .init(item))
                            }, footer: CelestiaString("Reference vectors are only visible for the current selected solar system object.", comment: ""))
                        ]
                    )
                )
            )
        ])
}

#if !os(visionOS)
public func timeAndRegionSettings() -> SettingSection {
    return SettingSection(
        title: CelestiaString("Time & Region", comment: "time and region related settings"),
        items: [
            SettingItem(
                name: CelestiaString("Time Zone", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Time Zone", comment: ""),
                        sections: [
                            AssociatedSelectionItem(
                                key: "timeZone",
                                items: [
                                    SettingSelectionItem(name: CelestiaString("Local Time", comment: ""), index: 0),
                                    SettingSelectionItem(name: CelestiaString("UTC", comment: ""), index: 1),
                                ]
                            ).toSection()
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Date Format", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Date Format", comment: ""),
                        sections: [
                            AssociatedSelectionItem(
                                key: "dateFormat",
                                items: [
                                    SettingSelectionItem(name: CelestiaString("Default", comment: ""), index: 0),
                                    SettingSelectionItem(name: CelestiaString("YYYY MMM DD HH:MM:SS TZ", comment: ""), index: 1),
                                    SettingSelectionItem(name: CelestiaString("UTC Offset", comment: ""), index: 2),
                                ]
                            ).toSection()
                        ]
                    )
                )
            ),
            SettingItem(name: CelestiaString("Current Time", comment: ""), type: .time, associatedItem: .init(0)),
            SettingItem(
                name: CelestiaString("Measure Units", comment: "Measurement system"),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Measure Units", comment: "Measurement system"),
                        sections: [
                            AssociatedSelectionItem(
                                key: "measurementSystem",
                                items: [
                                    SettingSelectionItem(name: CelestiaString("Metric", comment: "Metric measurement system"), index: 0),
                                    SettingSelectionItem(name: CelestiaString("Imperial", comment: "Imperial measurement system"), index: 1),
                                ]
                            ).toSection(),
                            AssociatedSelectionItem(
                                key: "temperatureScale",
                                items: [
                                    SettingSelectionItem(name: CelestiaString("Kelvin", comment: "Temperature scale"), index: 0),
                                    SettingSelectionItem(name: CelestiaString("Celsius", comment: "Temperature scale"), index: 1),
                                    SettingSelectionItem(name: CelestiaString("Fahrenheit", comment: "Temperature scale"), index: 2),
                                ]
                            ).toSection(header: CelestiaString("Temperature Scale", comment: ""))
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Info Display", comment: "HUD display"),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Info Display", comment: "HUD display"),
                        sections: [
                            AssociatedSelectionItem(
                                key: "hudDetail",
                                items: [
                                    SettingSelectionItem(name: CelestiaString("None", comment: "Empty HUD display"), index: 0),
                                    SettingSelectionItem(name: CelestiaString("Terse", comment: "Terse HUD display"), index: 1),
                                    SettingSelectionItem(name: CelestiaString("Verbose", comment: "Verbose HUD display"), index: 2),
                                ]
                            ).toSection()
                        ]
                    )
                )
            ),
        ])
}
#endif

public func rendererSettings(extraItems: [SettingItem<AnyHashable>]) -> SettingSection {
    var items: [SettingItem<AnyHashable>] = [
        SettingItem(
            name: CelestiaString("Texture Resolution", comment: ""),
            type: .common,
            associatedItem: .init(
                AssociatedCommonItem(
                    title: CelestiaString("Texture Resolution", comment: ""),
                    sections: [
                        AssociatedSelectionItem(
                            key: "resolution",
                            items: [
                                SettingSelectionItem(name: CelestiaString("Low", comment: "Low resolution"), index: 0),
                                SettingSelectionItem(name: CelestiaString("Medium", comment: "Medium resolution"), index: 1),
                                SettingSelectionItem(name: CelestiaString("High", comment: "High resolution"), index: 2),
                            ]
                        ).toSection()
                    ]
                )
            )
        ),
        SettingItem(
            name: CelestiaString("Star Style", comment: ""),
            type: .common,
            associatedItem: .init(
                AssociatedCommonItem(
                    title: CelestiaString("Star Style", comment: ""),
                    sections: [
                        .init(header: nil, rows: [
                            SettingItem(name: CelestiaString("Star Style", comment: ""), type: .selection, associatedItem: .init(
                                AssociatedSelectionSingleItem(key: "starStyle", options: [
                                    .init(name: CelestiaString("Fuzzy Points", comment: "Star style"), value: 0),
                                    .init(name: CelestiaString("Points", comment: "Star style"), value: 1),
                                    .init(name: CelestiaString("Scaled Discs", comment: "Star style"), value: 2),
                                ], defaultOption: 0)
                            )),
                            SettingItem(name: CelestiaString("Star Colors", comment: ""), type: .selection, associatedItem: .init(
                                AssociatedSelectionSingleItem(key: "starColors", options: [
                                    .init(name: CelestiaString("Classic Colors", comment: "Star colors option"), value: 0),
                                    .init(name: CelestiaString("Blackbody D65", comment: "Star colors option"), value: 1),
                                    .init(name: CelestiaString("Blackbody (Solar Whitepoint)", comment: "Star colors option"), value: 2),
                                    .init(name: CelestiaString("Blackbody (Vega Whitepoint)", comment: "Star colors option"), value: 3),
                                ], defaultOption: 1)
                            )),
                            SettingItem(
                                name: CelestiaString("Tinted Illumination Saturation", comment: ""),
                                type: .slider,
                                associatedItem: .init(
                                    AssociatedSliderItem(key: "tintSaturation", minValue: 0, maxValue: 1)
                                )
                            ),
                        ], footer: CelestiaString("Tinted illumination saturation setting is only effective with Blackbody star colors.", comment: ""))
                    ]
                )
            )
        ),
        SettingItem(
            name: CelestiaString("Render Parameters", comment: "Render parameters in setting"),
            type: .common,
            associatedItem: .init(
                AssociatedCommonItem(
                    title: CelestiaString("Render Parameters", comment: "Render parameters in setting"),
                    sections: [
                        .init(header: nil, rows: [
                            SettingItem(
                                name: CelestiaString("Smooth Lines", comment: "Smooth lines for rendering"),
                                type: .checkmark,
                                associatedItem: .init(
                                    AssociatedCheckmarkItem(name: CelestiaString("Smooth Lines", comment: "Smooth lines for rendering"), key: "showSmoothLines", representation: .switch)
                                )
                            ),
                        ], footer: nil),
                        .init(header: nil, rows: [
                            SettingItem(
                                name: CelestiaString("Auto Mag", comment: "Auto mag for star display"),
                                type: .checkmark,
                                associatedItem: .init(
                                    AssociatedCheckmarkItem(name: CelestiaString("Auto Mag", comment: "Auto mag for star display"), key: "showAutoMag", representation: .switch)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Ambient Light", comment: "In setting"),
                                type: .slider,
                                associatedItem: .init(
                                    AssociatedSliderItem(key: "ambientLightLevel", minValue: 0, maxValue: 1)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Faintest Stars", comment: "Control the faintest star that Celestia should display"),
                                type: .slider,
                                associatedItem: .init(
                                    AssociatedSliderItem(key: "faintestVisible", minValue: 3, maxValue: 12)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Galaxy Brightness", comment: "Render parameter"),
                                type: .slider,
                                associatedItem: .init(
                                    AssociatedSliderItem(key: "galaxyBrightness", minValue: 0, maxValue: 1)
                                )
                            ),
                        ], footer: nil),
                    ]
                )
            )
        ),
    ]
    #if !os(visionOS)
    items.append(SettingItem(name: CelestiaString("Frame Rate", comment: "Frame rate of simulation"), type: .frameRate, associatedItem: .init(0)))
    #endif
    items.append(contentsOf: extraItems)
    items.append(SettingItem(name: CelestiaString("Render Info", comment: "Information about renderer"), type: .render, associatedItem: .init(0)))

    return SettingSection(title: CelestiaString("Renderer", comment: "In settings"), items: items)
}

#if !os(visionOS)
@available(iOS 15, *)
public func celestiaPlusSettings() -> SettingSection {
    var items = [
        SettingItem<AnyHashable>(name: CelestiaString("Font", comment: ""), type: .font, associatedItem: .init(0)),
    ]
    #if !targetEnvironment(macCatalyst)
    items.insert(SettingItem<AnyHashable>(name: CelestiaString("Toolbar", comment: "Toolbar customization entry in Settings"), type: .toolbar, associatedItem: .init(0)), at: 0)
    #endif
    return SettingSection(title: CelestiaString("Celestia PLUS", comment: "Name for the subscription service"), items: items)
}
#endif

private let gamepadActions = GameControllerAction.allCases.map { action in
    SettingPreferenceSelectionItem.Option(name: action.name, value: action.rawValue)
}

public let gameControllerItem = SettingItem<AnyHashable>(
    name: CelestiaString("Game Controller", comment: "Settings for game controller"),
    type: .common,
    associatedItem: .init(
        AssociatedCommonItem(
            title: CelestiaString("Game Controller", comment: "Settings for game controller"),
            sections: [
                .init(header: CelestiaString("Buttons", comment: "Settings for game controller buttons"), rows: [
                    SettingItem(
                        name: CelestiaString("A / X", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapA, options: gamepadActions, defaultOption: GameControllerAction.moveSlower.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("B / Circle", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapB, options: gamepadActions, defaultOption: GameControllerAction.noop.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("X / Square", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapX, options: gamepadActions, defaultOption: GameControllerAction.moveFaster.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("Y / Triangle", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapY, options: gamepadActions, defaultOption: GameControllerAction.noop.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("LB / L1", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapLB, options: gamepadActions, defaultOption: GameControllerAction.noop.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("LT / L2", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapLT, options: gamepadActions, defaultOption: GameControllerAction.rollLeft.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("RB / R1", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapRB, options: gamepadActions, defaultOption: GameControllerAction.noop.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("RT / R2", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapRT, options: gamepadActions, defaultOption: GameControllerAction.rollRight.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("D-pad Up", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapDpadUp, options: gamepadActions, defaultOption: GameControllerAction.pitchUp.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("D-pad Down", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapDpadDown, options: gamepadActions, defaultOption: GameControllerAction.pitchDown.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("D-pad Left", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapDpadLeft, options: gamepadActions, defaultOption: GameControllerAction.rollLeft.rawValue)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("D-pad Right", comment: "Game controller button"),
                        type: .prefSelection,
                        associatedItem: .init(
                            AssociatedPreferenceSelectionItem(key: .gameControllerRemapDpadRight, options: gamepadActions, defaultOption: GameControllerAction.rollRight.rawValue)
                        )
                    ),
                ], footer: nil),
                .init(header: CelestiaString("Thumbsticks", comment: "Settings for game controller thumbsticks"), rows: [
                    SettingItem(
                        name: CelestiaString("Invert Horizontally", comment: "Invert game controller thumbstick axis horizontally"),
                        type: .prefSwitch,
                        associatedItem: .init(
                            AssociatedPreferenceSwitchItem(key: .gameControllerInvertX, defaultOn: false)
                        )
                    ),
                    SettingItem(
                        name: CelestiaString("Invert Vertically", comment: "Invert game controller thumbstick axis vertically"),
                        type: .prefSwitch,
                        associatedItem: .init(
                            AssociatedPreferenceSwitchItem(key: .gameControllerInvertY, defaultOn: false)
                        )
                    ),
                ], footer: nil),
            ]
        )
    )
)

public func advancedSettings(extraItems: [SettingItem<AnyHashable>]) -> SettingSection {
    var items = extraItems
    #if !os(visionOS)
    items.append(SettingItem(name: CelestiaString("Data Location", comment: "Title for celestia.cfg, data location setting"), type: .dataLocation, associatedItem: .init(0)))
    #endif
    items.append(contentsOf: [
        SettingItem(
            name: CelestiaString("Security", comment: "Security settings title"),
            type: .common,
            associatedItem: .init(
                AssociatedCommonItem(
                    title: CelestiaString("Security", comment: "Security settings title"),
                    sections: [
                        .init(
                            header: nil,
                            rows: [
                                SettingItem(name: CelestiaString("Script System Access Policy", comment: "Policy for managing lua script's access to the system"), subtitle: CelestiaString("Lua scripts' access to the file system", comment: "Note for Script System Access Policy"), type: .selection, associatedItem: .init(
                                    AssociatedSelectionSingleItem(key: "scriptSystemAccessPolicy", options: [
                                        .init(name: CelestiaString("Ask", comment: "Script system access policy option"), value: 0),
                                        .init(name: CelestiaString("Allow", comment: "Script system access policy option"), value: 1),
                                        .init(name: CelestiaString("Deny", comment: "Script system access policy option"), value: 2),
                                    ], defaultOption: 1)
                                ))
                            ],
                            footer: nil
                        )
                    ]
                )
            )
        )
    ])
    return SettingSection(title: CelestiaString("Advanced", comment: "Advanced setting items"), items: items)
}

public func miscSettings() -> SettingSection {
    return SettingSection(
        title: nil,
        items: [
            SettingItem(
                name: CelestiaString("Debug", comment: "Debug menu"),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Debug", comment: "Debug menu"),
                        items: [
                            SettingItem(
                                name: CelestiaString("Toggle FPS Display", comment: "Toggle FPS display on overlay"),
                                type: .action,
                                associatedItem: .init(
                                    AssociatedActionItem(action: 0x60)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Toggle Console Display", comment: "Toggle console log display on overlay"),
                                type: .action,
                                associatedItem: .init(
                                    AssociatedActionItem(action: 0x7E)
                                )
                            )
                        ]
                    )
                )
            ),
            SettingItem(name: CelestiaString("About", comment: "About Celstia..."), type: .about, associatedItem: .init(0))
        ])
}
