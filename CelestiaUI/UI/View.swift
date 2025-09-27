// View+Extension.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import SwiftUI

@available(iOS 26, visionOS 26, *)
extension View {
    @ViewBuilder func glassButtonStyle(prominent: Bool) -> some View {
        if prominent {
            prominentGlassButtonStyle()
        } else {
            glassButtonStyle()
        }
    }

    func glassButtonStyle() -> some View {
        #if os(visionOS)
        return self.buttonStyle(.borderedProminent)
        #else
        return self.buttonStyle(.glass)
        #endif
    }

    func prominentGlassButtonStyle() -> some View {
        #if os(visionOS)
        return self.buttonStyle(.borderedProminent)
        #else
        return self.buttonStyle(.glassProminent)
        #endif
    }
}
