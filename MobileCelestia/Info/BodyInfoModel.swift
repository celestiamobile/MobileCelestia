//
//  BodyInfoModel.swift
//  MobileCelestia
//
//  Created by Li Linfeng on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import Foundation

import CelestiaCore

struct BodyInfo {
    let name: String
    let overview: String

    fileprivate let selection: CelestiaSelection
}

extension BodyInfo {
    var url: URL? {
        guard let url = selection.webInfoURL else { return nil }
        return URL(string: url)
    }
}

extension CelestiaAppCore {
    var selection: BodyInfo {
        get { return BodyInfo(selection: simulation.selection) }
        set { simulation.selection = newValue.selection }
    }
}

extension BodyInfo {
    init(selection: CelestiaSelection) {
        let core = CelestiaAppCore.shared
        self.init(name: core.simulation.universe.name(for: selection),
                  overview: core.overviewForSelection(selection), selection: selection)
    }
}
