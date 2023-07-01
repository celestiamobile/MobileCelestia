//
// BodyInfoModel.swift
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

struct BodyInfo {
    let name: String
    let overview: String

    fileprivate let selection: Selection
}

extension BodyInfo {
    var url: URL? {
        guard let url = selection.webInfoURL else { return nil }
        return URL(string: url)
    }
}

extension AppCore {
    var selection: BodyInfo {
        get { return BodyInfo(selection: simulation.selection, core: self) }
        set { simulation.selection = newValue.selection }
    }
}

extension BodyInfo {
    init(selection: Selection, core: AppCore) {
        self.init(name: core.simulation.universe.name(for: selection),
                  overview: core.overviewForSelection(selection), selection: selection)
    }
}
