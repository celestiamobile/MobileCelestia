//
//  SettingModel.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import Foundation

enum SettingType {
    case checkmarks(masterKey: String?, items: [SettingCheckmarkItem])
}

struct SettingCheckmarkItem {
    let name: String
    let key: String
}

struct SettingItem {
    let name: String
    let type: SettingType
}

struct SettingSection {
    let title: String
    let items: [SettingItem]
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
                    ])),
        SettingItem(name: NSLocalizedString("Orbits", comment: ""),
                    type: .checkmarks(masterKey: "showOrbits", items: [
                    ])),
        SettingItem(name: NSLocalizedString("Grids", comment: ""),
                    type: .checkmarks(masterKey: nil, items: [
                    ])),
        SettingItem(name: NSLocalizedString("Constellations", comment: ""),
                    type: .checkmarks(masterKey: nil, items: [
                    ])),
        SettingItem(name: NSLocalizedString("Object Labels", comment: ""),
                    type: .checkmarks(masterKey: nil, items: [
                    ])),
        SettingItem(name: NSLocalizedString("Locations", comment: ""),
                    type: .checkmarks(masterKey: "showLocationLabels", items: [
                    ])),
    ]),
]
