// SystemAccessRequestWindow.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import SwiftUI

struct SystemAccessRequestWindow: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPresented = true

    var decision: (Bool) -> Void

    var body: some View {
        Color.clear
            .alert(
                CelestiaString("Script System Access", comment: "Alert title for scripts requesting system access"),
                isPresented: $isPresented,
                actions: {
                    Button(CelestiaString("OK", comment: "")) {
                        decision(true)
                    }
                    Button(CelestiaString("Cancel", comment: "")) {
                        decision(false)
                    }
                }, message: {
                    Text(CelestiaString("This script requests permission to read/write files and execute external programs. Allowing this can be dangerous.\nDo you trust the script and want to allow this?", comment: "Alert message for scripts requesting system access"))
                })
            .onChange(of: isPresented) { _, newValue in
                if !newValue {
                    dismiss()
                }
            }
    }
}
