// AlertWindow.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import SwiftUI

enum AlertContent: Codable, Hashable {
    case information(text: String)
    case celURL(url: URL)
    case celScript(url: URL)
}

struct AlertWindow: View {
    let content: AlertContent?

    @Environment(XRRenderer.self) private var renderer
    @Environment(\.dismiss) private var dismiss
    @State private var isPresented = true

    var body: some View {
        Group {
            switch content {
            case .information(let text):
                Color.clear
                    .alert(text, isPresented: $isPresented) {
                        Button(CelestiaString("OK", comment: "")) {}
                    }
            case .celURL(let url):
                Color.clear
                    .alert(CelestiaString("Open URL?", comment: "Request user consent to open a URL"), isPresented: $isPresented) {
                        Button(CelestiaString("OK", comment: "")) {
                            renderer.enqueue { core in
                                core.go(to: url.absoluteString)
                            }
                        }
                        Button(CelestiaString("Cancel", comment: ""), role: .cancel) {}
                    }
            case .celScript(let url):
                Color.clear
                    .alert(CelestiaString("Run script?", comment: "Request user consent to run a script"), isPresented: $isPresented) {
                        Button(CelestiaString("OK", comment: "")) {
                            renderer.enqueue { core in
                                core.runScript(at: url.path)
                            }
                        }
                        Button(CelestiaString("Cancel", comment: ""), role: .cancel) {}
                    }
            case .none:
                Color.clear
                    .onAppear {
                        isPresented = false
                    }
            }
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                dismiss()
            }
        }
    }
}
