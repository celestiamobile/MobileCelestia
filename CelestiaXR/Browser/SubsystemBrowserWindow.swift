// SubsystemBrowserWindow.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import SwiftUI

struct SubsystemBrowserWindow: View {
    @Environment(BrowserItemStore.self) private var browerItemStore

    let id: UUID

    var body: some View {
        if let item = browerItemStore.getItem(by: id) {
            SubsystemBrowserView(item: item)
        } else {
            EmptyView()
        }
    }
}
