// InfoWindow.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaUI
import SwiftUI

struct InfoWindow: View {
    @Environment(XRRenderer.self) private var renderer

    var body: some View {
        if !renderer.selection.isEmpty {
            InfoView(selection: renderer.selection, isEmbeddedInNavigationController: false)
        } else {
            Text(CelestiaString("No object is selected…", comment: ""))
        }
    }
}
