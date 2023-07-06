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

let mainSetting = [
    SettingSection(
        title: CelestiaString("Display", comment: ""),
        items: [
            SettingItem(
                name: CelestiaString("Objects", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Objects", comment: ""),
                        sections: [
                            [
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
                                name: CelestiaString("Stars", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Stars", comment: ""), key: "showStellarOrbits", representation: .checkmark)
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
                                name: CelestiaString("Spacecraft", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Spacecraft", comment: ""), key: "showSpacecraftOrbits", representation: .checkmark)
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
                                name: CelestiaString("Equatorial", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Equatorial", comment: ""), key: "showCelestialSphere", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Ecliptic", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Ecliptic", comment: ""), key: "showEclipticGrid", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Horizontal", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Horizontal", comment: ""), key: "showHorizonGrid", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Galactic", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Galactic", comment: ""), key: "showGalacticGrid", representation: .checkmark)
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
                            name: CelestiaString("Show Diagrams", comment: ""),
                            type: .checkmark,
                            associatedItem: .init(
                                SettingCheckmarkItem(name: CelestiaString("Show Diagrams", comment: ""), key: "showDiagrams", representation: .checkmark)
                            )
                        ),
                        SettingItem(
                            name: CelestiaString("Show Labels", comment: ""),
                            type: .checkmark,
                            associatedItem: .init(
                                SettingCheckmarkItem(name: CelestiaString("Show Labels", comment: ""), key: "showConstellationLabels", representation: .checkmark)
                            )
                        ),
                        SettingItem(
                            name: CelestiaString("Show Labels in Latin", comment: ""),
                            type: .checkmark,
                            associatedItem: .init(
                                SettingCheckmarkItem(name: CelestiaString("Show Labels in Latin", comment: ""), key: "showLatinConstellationLabels", representation: .checkmark)
                            )
                        ),
                        SettingItem(
                            name: CelestiaString("Show Boundaries", comment: ""),
                            type: .checkmark,
                            associatedItem: .init(
                                SettingCheckmarkItem(name: CelestiaString("Show Boundaries", comment: ""), key: "showBoundaries", representation: .checkmark)
                            )
                        ),
                    ])
                )
            ),
            SettingItem(
                name: CelestiaString("Object Labels", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Object Labels", comment: ""),
                        sections: [
                            [
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
                            ].toSection()
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Locations", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(title: CelestiaString("Locations", comment: ""), sections: [
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
                                name: CelestiaString("Minimum Labeled Feature Size", comment: ""),
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
                                name: CelestiaString("Observatories", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Observatories", comment: ""), key: "showObservatoryLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Landing Sites", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Landing Sites", comment: ""), key: "showLandingSiteLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Montes (Mountains)", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Montes (Mountains)", comment: ""), key: "showMonsLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Maria (Seas)", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Maria (Seas)", comment: ""), key: "showMareLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Craters", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Craters", comment: ""), key: "showCraterLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Valles (Valleys)", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Valles (Valleys)", comment: ""), key: "showVallisLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Terrae (Land masses)", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Terrae (Land masses)", comment: ""), key: "showTerraLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Volcanoes", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Volcanoes", comment: ""), key: "showEruptiveCenterLabels", representation: .checkmark)
                                )
                            ),
                            SettingItem(
                                name: CelestiaString("Other", comment: ""),
                                type: .checkmark,
                                associatedItem: .init(
                                    SettingCheckmarkItem(name: CelestiaString("Other", comment: ""), key: "showOtherLabels", representation: .checkmark)
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
                                    name: CelestiaString("Unmark All", comment: ""),
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
                name: CelestiaString("Reference Vectors", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Reference Vectors", comment: ""),
                        sections: [
                            .init(header: nil, rows: [
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
        title: CelestiaString("Time & Region", comment: ""),
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
                name: CelestiaString("Measure Units", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Measure Units", comment: ""),
                        sections: [
                            AssociatedSelectionItem(
                                key: "measurementSystem",
                                items: [
                                    SettingSelectionItem(name: CelestiaString("Metric", comment: ""), index: 0),
                                    SettingSelectionItem(name: CelestiaString("Imperial", comment: ""), index: 1),
                                ]
                            ).toSection(),
                            AssociatedSelectionItem(
                                key: "temperatureScale",
                                items: [
                                    SettingSelectionItem(name: CelestiaString("Kelvin", comment: ""), index: 0),
                                    SettingSelectionItem(name: CelestiaString("Celsius", comment: ""), index: 1),
                                    SettingSelectionItem(name: CelestiaString("Fahrenheit", comment: ""), index: 2),
                                ]
                            ).toSection(header: CelestiaString("Temperature Scale", comment: ""))
                        ]
                    )
                )
            ),
            SettingItem(
                name: CelestiaString("Info Display", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Info Display", comment: ""),
                        sections: [
                            AssociatedSelectionItem(
                                key: "hudDetail",
                                items: [
                                    SettingSelectionItem(name: CelestiaString("None", comment: ""), index: 0),
                                    SettingSelectionItem(name: CelestiaString("Terse", comment: ""), index: 1),
                                    SettingSelectionItem(name: CelestiaString("Verbose", comment: ""), index: 2),
                                ]
                            ).toSection()
                        ]
                    )
                )
            ),
        ]),
    SettingSection(
        title: CelestiaString("Renderer", comment: ""),
        items: [
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
                                    SettingSelectionItem(name: CelestiaString("Low", comment: ""), index: 0),
                                    SettingSelectionItem(name: CelestiaString("Medium", comment: ""), index: 1),
                                    SettingSelectionItem(name: CelestiaString("High", comment: ""), index: 2),
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
                                        .init(name: CelestiaString("Fuzzy Points", comment: ""), value: 0),
                                        .init(name: CelestiaString("Points", comment: ""), value: 1),
                                        .init(name: CelestiaString("Scaled Discs", comment: ""), value: 2),
                                    ], defaultOption: 0)
                                )),
                                SettingItem(name: CelestiaString("Star Colors", comment: ""), type: .selection, associatedItem: .init(
                                    AssociatedSelectionSingleItem(key: "starColors", options: [
                                        .init(name: CelestiaString("Classic Colors", comment: ""), value: 0),
                                        .init(name: CelestiaString("Blackbody D65", comment: ""), value: 1),
                                    ], defaultOption: 1)
                                )),
                                SettingItem(
                                    name: CelestiaString("Tinted Illumination Saturation", comment: ""),
                                    type: .slider,
                                    associatedItem: .init(
                                        AssociatedSliderItem(key: "tintSaturation", minValue: 0, maxValue: 1)
                                    )
                                ),
                            ], footer: CelestiaString("Tinted illumination saturation setting is only effective with Blackbody D65 star colors.", comment: ""))
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
                            .init(header: nil, rows: [
                                SettingItem(
                                    name: CelestiaString("Smooth Lines", comment: ""),
                                    type: .checkmark,
                                    associatedItem: .init(
                                        AssociatedCheckmarkItem(name: CelestiaString("Smooth Lines", comment: ""), key: "showSmoothLines", representation: .switch)
                                    )
                                ),
                            ], footer: nil),
                            .init(header: nil, rows: [
                                SettingItem(
                                    name: CelestiaString("Auto Mag", comment: ""),
                                    type: .checkmark,
                                    associatedItem: .init(
                                        AssociatedCheckmarkItem(name: CelestiaString("Auto Mag", comment: ""), key: "showAutoMag", representation: .switch)
                                    )
                                ),
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
                                    name: CelestiaString("Galaxy Brightness", comment: ""),
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
            SettingItem(name: CelestiaString("Frame Rate", comment: ""), type: .frameRate, associatedItem: .init(0)),
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
                                ),
                            ], footer: CelestiaString("Configuration will take effect after a restart.", comment: "")),
                        ]
                    )
                )
            ),
            SettingItem(name: CelestiaString("Render Info", comment: ""), type: .render, associatedItem: .init(0)),
        ]),
    SettingSection(
        title: CelestiaString("Advanced", comment: ""),
        items: [
            SettingItem(
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
            ),
            SettingItem(name: CelestiaString("Data Location", comment: ""), type: .dataLocation, associatedItem: .init(0)),
            SettingItem(
                name: CelestiaString("Security", comment: ""),
                type: .common,
                associatedItem: .init(
                    AssociatedCommonItem(
                        title: CelestiaString("Security", comment: ""),
                        sections: [
                            AssociatedSelectionItem(
                                key: "scriptSystemAccessPolicy",
                                items: [
                                    SettingSelectionItem(name: CelestiaString("Ask", comment: ""), index: 0),
                                    SettingSelectionItem(name: CelestiaString("Allow", comment: ""), index: 1),
                                    SettingSelectionItem(name: CelestiaString("Deny", comment: ""), index: 2),
                                ]
                            ).toSection(header: CelestiaString("Script System Access Policy", comment: ""), footer: CelestiaString("This policy decides whether Lua scripts have access to the files on the system or not.", comment: ""))
                        ]
                    )
                )
            )
        ]),
    SettingSection(
        title: nil,
        items: [
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
