//
//  SettingModel.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import Foundation

enum SettingType {
    case checkmarks(masterKey: String?, items: [SettingCheckmarkItem])
    case selection(key: String, items: [SettingSelectionItem])
    case about
    case render
    case time
    case dataLocation
}

struct SettingCheckmarkItem {
    let name: String
    let key: String
}

struct SettingSelectionItem {
    let name: String
    let index: Int
}

struct SettingItem {
    let name: String
    let type: SettingType
}

struct SettingSection {
    let title: String
    let items: [SettingItem]
}

enum TextItem {
    case short(title: String, detail: String?)
    case long(content: String)
    case link(title: String, url: URL)
}

let mainSetting = [
    SettingSection(title: CelestiaString("Display", comment: ""), items: [
        SettingItem(name: CelestiaString("Objects", comment: ""),
                    type: .checkmarks(masterKey: nil, items: [
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
                    ])),
        SettingItem(name: CelestiaString("Features", comment: ""),
                    type: .checkmarks(masterKey: nil, items: [
                        SettingCheckmarkItem(name: CelestiaString("Atmospheres", comment: ""), key: "showAtmospheres"),
                        SettingCheckmarkItem(name: CelestiaString("Clouds", comment: ""), key: "showCloudMaps"),
                        SettingCheckmarkItem(name: CelestiaString("Cloud Shadows", comment: ""), key: "showCloudShadows"),
                        SettingCheckmarkItem(name: CelestiaString("Night Lights", comment: ""), key: "showNightMaps"),
                        SettingCheckmarkItem(name: CelestiaString("Planet Rings", comment: ""), key: "showPlanetRings"),
                        SettingCheckmarkItem(name: CelestiaString("Ring Shadows", comment: ""), key: "showRingShadows"),
                        SettingCheckmarkItem(name: CelestiaString("Comet Tails", comment: ""), key: "showCometTails"),
                        SettingCheckmarkItem(name: CelestiaString("Eclipse Shadows", comment: ""), key: "showEclipseShadows"),
                    ])),
        SettingItem(name: CelestiaString("Orbits", comment: ""),
                    type: .checkmarks(masterKey: "showOrbits", items: [
                        SettingCheckmarkItem(name: CelestiaString("Stars", comment: ""), key: "showStellarOrbits"),
                        SettingCheckmarkItem(name: CelestiaString("Planets", comment: ""), key: "showPlanetOrbits"),
                        SettingCheckmarkItem(name: CelestiaString("Dwarf Planets", comment: ""), key: "showDwarfPlanetOrbits"),
                        SettingCheckmarkItem(name: CelestiaString("Moons", comment: ""), key: "showMoonOrbits"),
                        SettingCheckmarkItem(name: CelestiaString("Minor Moons", comment: ""), key: "showMinorMoonOrbits"),
                        SettingCheckmarkItem(name: CelestiaString("Asteroids", comment: ""), key: "showAsteroidOrbits"),
                        SettingCheckmarkItem(name: CelestiaString("Comets", comment: ""), key: "showCometOrbits"),
                        SettingCheckmarkItem(name: CelestiaString("Spacecraft", comment: ""), key: "showSpacecraftOrbits"),
                    ])),
        SettingItem(name: CelestiaString("Grids", comment: ""),
                    type: .checkmarks(masterKey: nil, items: [
                        SettingCheckmarkItem(name: CelestiaString("Equatorial", comment: ""), key: "showCelestialSphere"),
                        SettingCheckmarkItem(name: CelestiaString("Ecliptic", comment: ""), key: "showEclipticGrid"),
                        SettingCheckmarkItem(name: CelestiaString("Horizontal", comment: ""), key: "showHorizonGrid"),
                        SettingCheckmarkItem(name: CelestiaString("Galactic", comment: ""), key: "showGalacticGrid"),
                    ])),
        SettingItem(name: CelestiaString("Constellations", comment: ""),
                    type: .checkmarks(masterKey: "showDiagrams", items: [
                        SettingCheckmarkItem(name: CelestiaString("Constellation Labels", comment: ""), key: "showConstellationLabels"),
                        SettingCheckmarkItem(name: CelestiaString("Constellations in Latin", comment: ""), key: "showLatinConstellationLabels"),
                        SettingCheckmarkItem(name: CelestiaString("Show Boundaries", comment: ""), key: "showBoundaries"),
                    ])),
        SettingItem(name: CelestiaString("Object Labels", comment: ""),
                    type: .checkmarks(masterKey: nil, items: [
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
                    ])),
        SettingItem(name: CelestiaString("Locations", comment: ""),
                    type: .checkmarks(masterKey: "showLocationLabels", items: [
                        SettingCheckmarkItem(name: CelestiaString("Cities", comment: ""), key: "showCityLabels"),
                        SettingCheckmarkItem(name: CelestiaString("Observatories", comment: ""), key: "showObservatoryLabels"),
                        SettingCheckmarkItem(name: CelestiaString("Landing Sites", comment: ""), key: "showLandingSiteLabels"),
                        SettingCheckmarkItem(name: CelestiaString("Mons", comment: ""), key: "showMonsLabels"),
                        SettingCheckmarkItem(name: CelestiaString("Mare", comment: ""), key: "showMareLabels"),
                        SettingCheckmarkItem(name: CelestiaString("Crater", comment: ""), key: "showCraterLabels"),
                        SettingCheckmarkItem(name: CelestiaString("Vallis", comment: ""), key: "showVallisLabels"),
                        SettingCheckmarkItem(name: CelestiaString("Terra", comment: ""), key: "showTerraLabels"),
                        SettingCheckmarkItem(name: CelestiaString("Volcanoes", comment: ""), key: "showEruptiveCenterLabels"),
                    ])),
    ]),
    SettingSection(title: CelestiaString("Time", comment: ""), items: [
        SettingItem(name: CelestiaString("Time Zone", comment: ""),
                    type: .selection(key: "timeZone", items: [
            SettingSelectionItem(name: CelestiaString("Local Time", comment: ""), index: 0),
            SettingSelectionItem(name: CelestiaString("UTC", comment: ""), index: 1),
        ])),
        SettingItem(name: CelestiaString("Date Format", comment: ""),
                    type: .selection(key: "dateFormat", items: [
            SettingSelectionItem(name: CelestiaString("Default", comment: ""), index: 0),
            SettingSelectionItem(name: CelestiaString("YYYY MMM DD HH:MM:SS TZ", comment: ""), index: 1),
            SettingSelectionItem(name: CelestiaString("UTC Offset", comment: ""), index: 2),
        ])),
        SettingItem(name: CelestiaString("Current Time", comment: ""), type: .time)
    ]),
    SettingSection(title: CelestiaString("Advanced", comment: ""), items: [
        SettingItem(name: CelestiaString("Texture Resolution", comment: ""),
                    type: .selection(key: "resolution", items: [
            SettingSelectionItem(name: CelestiaString("Low", comment: ""), index: 0),
            SettingSelectionItem(name: CelestiaString("Medium", comment: ""), index: 1),
            SettingSelectionItem(name: CelestiaString("High", comment: ""), index: 2),
        ])),
        SettingItem(name: CelestiaString("Star Style", comment: ""),
                    type: .selection(key: "starStyle", items: [
            SettingSelectionItem(name: CelestiaString("Fuzzy Points", comment: ""), index: 0),
            SettingSelectionItem(name: CelestiaString("Points", comment: ""), index: 1),
            SettingSelectionItem(name: CelestiaString("Scaled Discs", comment: ""), index: 2),
        ])),
        SettingItem(name: CelestiaString("Info Display", comment: ""),
                    type: .selection(key: "hudDetail", items: [
            SettingSelectionItem(name: CelestiaString("None", comment: ""), index: 0),
            SettingSelectionItem(name: CelestiaString("Terse", comment: ""), index: 1),
            SettingSelectionItem(name: CelestiaString("Verbose", comment: ""), index: 2),
        ])),
        SettingItem(name: CelestiaString("Data Location", comment: ""), type: .dataLocation),
    ]),
    SettingSection(title: CelestiaString("Others", comment: ""), items: [
        SettingItem(name: CelestiaString("Render Info", comment: ""), type: .render),
        SettingItem(name: CelestiaString("About", comment: ""), type: .about)
    ])
]
