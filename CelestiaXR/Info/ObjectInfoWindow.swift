// ObjectInfoWindow.swift
//
// Copyright (C) 2026, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaUI
import SwiftUI

struct ObjectInfoWindow: View {
    @Environment(XRRenderer.self) private var renderer
    @State private var selection: Selection?

    let objectPath: String

    var body: some View {
        if let selection {
            if !selection.isEmpty {
                InfoView(selection: selection, isEmbeddedInNavigationController: false)
            } else {
                Text(CelestiaString("Object not found…", comment: ""))
            }
        } else {
            ProgressView()
                .task {
                    let core = renderer.appCore
                    selection = await Task { @CelestiaActor in
                        core.simulation.findObject(from: objectPath)
                    }.value
                }
        }
    }
}
