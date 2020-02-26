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
}

let mainSetting = [
    SettingSection(title: NSLocalizedString("Display", comment: ""), items: [
        SettingItem(name: NSLocalizedString("Objects", comment: ""),
                    type: .checkmarks(masterKey: nil, items: [
                        SettingCheckmarkItem(name: NSLocalizedString("Stars", comment: ""), key: "showStars"),
                        SettingCheckmarkItem(name: NSLocalizedString("Planets", comment: ""), key: "showPlanets"),
                        SettingCheckmarkItem(name: NSLocalizedString("Dwarf Planets", comment: ""), key: "showDwarfPlanets"),
                        SettingCheckmarkItem(name: NSLocalizedString("Moons", comment: ""), key: "showMoons"),
                        SettingCheckmarkItem(name: NSLocalizedString("Minor Moons", comment: ""), key: "showMinorMoons"),
                        SettingCheckmarkItem(name: NSLocalizedString("Asteroids", comment: ""), key: "showAsteroids"),
                        SettingCheckmarkItem(name: NSLocalizedString("Comets", comment: ""), key: "showComets"),
                        SettingCheckmarkItem(name: NSLocalizedString("Spacecrafts", comment: ""), key: "showSpacecrafts"),
                        SettingCheckmarkItem(name: NSLocalizedString("Galaxies", comment: ""), key: "showGalaxies"),
                        SettingCheckmarkItem(name: NSLocalizedString("Nebulae", comment: ""), key: "showNebulae"),
                        SettingCheckmarkItem(name: NSLocalizedString("Globulars", comment: ""), key: "showGlobulars"),
                        SettingCheckmarkItem(name: NSLocalizedString("Open Clusters", comment: ""), key: "showOpenClusters"),
                    ])),
        SettingItem(name: NSLocalizedString("Features", comment: ""),
                    type: .checkmarks(masterKey: nil, items: [
                        SettingCheckmarkItem(name: NSLocalizedString("Atmospheres", comment: ""), key: "showAtmospheres"),
                        SettingCheckmarkItem(name: NSLocalizedString("Clouds", comment: ""), key: "showCloudMaps"),
                        SettingCheckmarkItem(name: NSLocalizedString("Cloud Shadows", comment: ""), key: "showCloudShadows"),
                        SettingCheckmarkItem(name: NSLocalizedString("Night Lights", comment: ""), key: "showNightMaps"),
                        SettingCheckmarkItem(name: NSLocalizedString("Planet Rings", comment: ""), key: "showPlanetRings"),
                        SettingCheckmarkItem(name: NSLocalizedString("Ring Shadows", comment: ""), key: "showRingShadows"),
                        SettingCheckmarkItem(name: NSLocalizedString("Comet Tails", comment: ""), key: "showCometTails"),
                        SettingCheckmarkItem(name: NSLocalizedString("Eclipse Shadows", comment: ""), key: "showEclipseShadows"),
                    ])),
        SettingItem(name: NSLocalizedString("Orbits", comment: ""),
                    type: .checkmarks(masterKey: "showOrbits", items: [
                        SettingCheckmarkItem(name: NSLocalizedString("Stars", comment: ""), key: "showStellarOrbits"),
                        SettingCheckmarkItem(name: NSLocalizedString("Planets", comment: ""), key: "showPlanetOrbits"),
                        SettingCheckmarkItem(name: NSLocalizedString("Dwarf Planets", comment: ""), key: "showDwarfPlanetOrbits"),
                        SettingCheckmarkItem(name: NSLocalizedString("Moons", comment: ""), key: "showMoonOrbits"),
                        SettingCheckmarkItem(name: NSLocalizedString("Minor Moons", comment: ""), key: "showMinorMoonOrbits"),
                        SettingCheckmarkItem(name: NSLocalizedString("Asteroids", comment: ""), key: "showAsteroidOrbits"),
                        SettingCheckmarkItem(name: NSLocalizedString("Comets", comment: ""), key: "showCometOrbits"),
                        SettingCheckmarkItem(name: NSLocalizedString("Spacecrafts", comment: ""), key: "showSpacecraftOrbits"),
                    ])),
        SettingItem(name: NSLocalizedString("Grids", comment: ""),
                    type: .checkmarks(masterKey: nil, items: [
                        SettingCheckmarkItem(name: NSLocalizedString("Equatorial", comment: ""), key: "showCelestialSphere"),
                        SettingCheckmarkItem(name: NSLocalizedString("Ecliptic", comment: ""), key: "showEclipticGrid"),
                        SettingCheckmarkItem(name: NSLocalizedString("Horizontal", comment: ""), key: "showHorizonGrid"),
                        SettingCheckmarkItem(name: NSLocalizedString("Galactic", comment: ""), key: "showGalacticGrid"),
                    ])),
        SettingItem(name: NSLocalizedString("Constellations", comment: ""),
                    type: .checkmarks(masterKey: "showDiagrams", items: [
                        SettingCheckmarkItem(name: NSLocalizedString("Constellation Labels", comment: ""), key: "showConstellationLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Constellations in Latin", comment: ""), key: "showLatinConstellationLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Show Boundaries", comment: ""), key: "showBoundaries"),
                    ])),
        SettingItem(name: NSLocalizedString("Object Labels", comment: ""),
                    type: .checkmarks(masterKey: nil, items: [
                        SettingCheckmarkItem(name: NSLocalizedString("Stars", comment: ""), key: "showStarLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Planets", comment: ""), key: "showPlanetLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Dwarf Planets", comment: ""), key: "showDwarfPlanetLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Moons", comment: ""), key: "showMoonLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Minor Moons", comment: ""), key: "showMinorMoonLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Asteroids", comment: ""), key: "showAsteroidLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Comets", comment: ""), key: "showCometLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Spacecrafts", comment: ""), key: "showSpacecraftLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Galaxies", comment: ""), key: "showGalaxyLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Nebulae", comment: ""), key: "showNebulaLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Globulars", comment: ""), key: "showGlobularLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Open Clusters", comment: ""), key: "showOpenClusterLabels"),
                    ])),
        SettingItem(name: NSLocalizedString("Locations", comment: ""),
                    type: .checkmarks(masterKey: "showLocationLabels", items: [
                        SettingCheckmarkItem(name: NSLocalizedString("Cities", comment: ""), key: "showCityLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Observatories", comment: ""), key: "showObservatoryLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Landing Sites", comment: ""), key: "showLandingSiteLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Mons", comment: ""), key: "showMonsLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Mare", comment: ""), key: "showMareLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Crater", comment: ""), key: "showCraterLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Vallis", comment: ""), key: "showVallisLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Terra", comment: ""), key: "showTerraLabels"),
                        SettingCheckmarkItem(name: NSLocalizedString("Volcanoes", comment: ""), key: "showEruptiveCenterLabels"),
                    ])),
    ]),
    SettingSection(title: NSLocalizedString("Time", comment: ""), items: [
        SettingItem(name: NSLocalizedString("Time Zone", comment: ""),
                    type: .selection(key: "timeZone", items: [
            SettingSelectionItem(name: NSLocalizedString("Local Time", comment: ""), index: 0),
            SettingSelectionItem(name: NSLocalizedString("UTC", comment: ""), index: 1),
        ])),
        SettingItem(name: NSLocalizedString("Date Format", comment: ""),
                    type: .selection(key: "dateFormat", items: [
            SettingSelectionItem(name: NSLocalizedString("Default", comment: ""), index: 0),
            SettingSelectionItem(name: NSLocalizedString("YYYY MMM DD HH:MM:SS TZ", comment: ""), index: 1),
            SettingSelectionItem(name: NSLocalizedString("UTC Offset", comment: ""), index: 2),
        ])),
        SettingItem(name: NSLocalizedString("Current Time", comment: ""), type: .time)
    ]),
    SettingSection(title: NSLocalizedString("Advanced", comment: ""), items: [
        SettingItem(name: NSLocalizedString("Texture Resolution", comment: ""),
                    type: .selection(key: "resolution", items: [
            SettingSelectionItem(name: NSLocalizedString("Low", comment: ""), index: 0),
            SettingSelectionItem(name: NSLocalizedString("Medium", comment: ""), index: 1),
            SettingSelectionItem(name: NSLocalizedString("High", comment: ""), index: 2),
        ])),
        SettingItem(name: NSLocalizedString("Star Style", comment: ""),
                    type: .selection(key: "starStyle", items: [
            SettingSelectionItem(name: NSLocalizedString("Fuzzy Points", comment: ""), index: 0),
            SettingSelectionItem(name: NSLocalizedString("Points", comment: ""), index: 1),
            SettingSelectionItem(name: NSLocalizedString("Scaled Discs", comment: ""), index: 2),
        ])),
        SettingItem(name: NSLocalizedString("Info Display", comment: ""),
                    type: .selection(key: "hudDetail", items: [
            SettingSelectionItem(name: NSLocalizedString("None", comment: ""), index: 0),
            SettingSelectionItem(name: NSLocalizedString("Terse", comment: ""), index: 1),
            SettingSelectionItem(name: NSLocalizedString("Verbose", comment: ""), index: 2),
        ])),
    ]),
    SettingSection(title: NSLocalizedString("Others", comment: ""), items: [
        SettingItem(name: NSLocalizedString("Render Info", comment: ""), type: .render),
        SettingItem(name: NSLocalizedString("About", comment: ""), type: .about)
    ])
]
