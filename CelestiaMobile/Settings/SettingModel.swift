//
//  SettingModel.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import Foundation

struct SettingItem {
    let name: String
}

struct SettingSection {
    let title: String
    let items: [SettingItem]
}

let mainSetting = [
    SettingSection(title: NSLocalizedString("Display", comment: ""), items: [
        SettingItem(name: NSLocalizedString("Objects", comment: "")),
        SettingItem(name: NSLocalizedString("Features", comment: "")),
        SettingItem(name: NSLocalizedString("Orbits", comment: "")),
        SettingItem(name: NSLocalizedString("Grids", comment: "")),
        SettingItem(name: NSLocalizedString("Constellations", comment: "")),
        SettingItem(name: NSLocalizedString("Object labels", comment: "")),
        SettingItem(name: NSLocalizedString("Locations", comment: "")),
    ]),
]
