// BodyInfoModel.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation

import CelestiaCore

struct BodyInfo: @unchecked Sendable {
    let name: String
    let overview: NSAttributedString

    private let infoURL: String?
    private let selection: Selection
}

extension BodyInfo {
    var url: URL? {
        guard let url = infoURL else { return nil }
        return URL(string: url)
    }
}

extension BodyInfo {
    init(selection: Selection, core: AppCore) {
        self.init(
            name: core.simulation.universe.name(for: selection),
            overview: core.overviewForSelection(selection),
            infoURL: core.simulation.universe.webInfoURL(for: selection),
            selection: selection
        )
    }
}
