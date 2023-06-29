//
// RunningView.swift
//
// Copyright © 2024 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import SwiftUI

struct RunningView: View {
    @Environment(XRRenderer.self) private var renderer

    private let toolboxItems: [ToolboxView.Item] = [
        ToolboxView.Item(
            image: "info.circle",
            title: CelestiaString("Info", comment: "HUD display"),
            action: .openInfo
        ),
        ToolboxView.Item(
            image: "globe",
            title: CelestiaString("Star Browser", comment: ""),
            tool: .browser
        ),
        ToolboxView.Item(
            image: "magnifyingglass",
            title: CelestiaString("Search", comment: ""),
            tool: .search
        ),
        ToolboxView.Item(
            image: "paperplane",
            title: CelestiaString("Go to Object", comment: ""),
            tool: .goTo
        ),
        ToolboxView.Item(
            image: "calendar",
            title: CelestiaString("Eclipse Finder", comment: ""),
            tool: .eclipseFinder
        ),
        ToolboxView.Item(
            image: "video",
            title: CelestiaString("Camera Control", comment: "Observer control"),
            tool: .cameraControl
        ),
        ToolboxView.Item(
            image: "clock",
            title: CelestiaString("Current Time", comment: ""),
            tool: .currentTime
        ),
        ToolboxView.Item(
            image: "star.circle",
            title: CelestiaString("Favorites", comment: "Favorites (currently bookmarks and scripts)"),
            tool: .favorites
        ),
        ToolboxView.Item(
            image: "gear",
            title: CelestiaString("Settings", comment: ""),
            tool: .settings
        ),
        ToolboxView.Item(
            image: "folder",
            title: CelestiaString("Installed Add-ons", comment: "Open a page for managing installed add-ons"),
            tool: .installedAddons
        ),
        ToolboxView.Item(
            image: "square.and.arrow.down",
            title: CelestiaString("Get Add-ons", comment: "Open webpage for downloading add-ons"),
            tool: .downloadAddons
        ),
        ToolboxView.Item(
            image: "questionmark.circle",
            title: CelestiaString("Help", comment: ""),
            tool: .help
        ),
        ToolboxView.Item(
            image: "x.circle",
            title: CelestiaString("Pause", comment: "Pause time"),
            action: .pause
        ),
    ]

    let toolAction: (ToolboxView.Item.Action) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutConstants.mediumVerticalSpacing) {
                Section(header: Text(CelestiaString("Tools", comment: "Tools menu title")).font(.largeTitle)) {
                    ToolboxView(items: toolboxItems, action: toolAction)
                }
                if let state = renderer.state {
                    Section(header: Text(CelestiaString("Stats", comment: "")).font(.largeTitle)) {
                        StateView(state: state)
                            .font(.body)
                    }
                }
                if !renderer.message.isEmpty {
                    Section(header: Text(CelestiaString("Messages", comment: "")).font(.largeTitle)) {
                        Text(renderer.message)
                            .font(.largeTitle)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
