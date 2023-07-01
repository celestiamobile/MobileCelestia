//
// SubsystemBrowserWindow.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import SwiftUI

struct SubsystemBrowserWindow: View {
    @EnvironmentObject private var browerItemStore: BrowserItemStore

    let id: UUID

    var body: some View {
        if let item = browerItemStore.getItem(by: id) {
            SubsystemBrowserView(item: item)
        } else {
            EmptyView()
        }
    }
}
