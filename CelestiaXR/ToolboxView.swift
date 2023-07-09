//
// ToolboxView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import SwiftUI

struct ToolboxView: View {
    private enum Constants {
        static let minimumWidth: CGFloat = 200
    }

    @Environment(\.openWindow) private var openWindow

    struct Item: Identifiable {
        let image: String
        let title: String
        let windowGroupID: String
        let id = UUID()
    }

    let items: [Item]

    var body: some View {
        ToolboxLayout() {
            ForEach(items) { item in
                VStack(spacing: 12) {
                    Image(systemName: item.image)
                        .font(.largeTitle)
                    Text(item.title)
                }
                .contentShape(.interaction, .rect)
                .contentShape(.hoverEffect, .rect(cornerRadius: 16))
                .onTapGesture {
                    openWindow(id: item.windowGroupID)
                }
            }
        }
    }
}
