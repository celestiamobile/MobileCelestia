// ToolboxView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import SwiftUI

struct ToolboxView: View {
    struct Item: Identifiable {
        enum Action {
            case pause
            case openInfo
            case openTool(tool: WindowManager.Tool)
        }

        let image: String
        let title: String
        let action: Action
        let id = UUID()

        init(image: String, title: String, action: Action) {
            self.image = image
            self.title = title
            self.action = action
        }

        init(image: String, title: String, tool: WindowManager.Tool) {
            self.image = image
            self.title = title
            self.action = .openTool(tool: tool)
        }
    }

    let items: [Item]
    let action: (Item.Action) -> Void

    var body: some View {
        ToolboxLayout() {
            ForEach(items) { item in
                Button {
                    action(item.action)
                } label: {
                    VStack(spacing: LayoutConstants.smallVerticalSpacing) {
                        Image(systemName: item.image)
                            .font(.largeTitle)
                        Text(item.title)
                    }
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
