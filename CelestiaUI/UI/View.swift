// View+Extension.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import SwiftUI

@available(iOS 15, visionOS 1, *)
extension View {
    func safeArea(@ViewBuilder content: () -> some View) -> some View {
        #if os(visionOS)
        if #available(visionOS 26, *) {
            return safeAreaBar(edge: .bottom, content: content)
        } else {
            return VStack {
                self
                Spacer()
                content()
            }
        }
        #else
        if #available(iOS 26, *) {
            return safeAreaBar(edge: .bottom, content: content)
        } else {
            return safeAreaInset(edge: .bottom) {
                ZStack(content: content)
                    .frame(maxWidth: .infinity)
                    .background()
            }
        }
        #endif
    }
}

@available(iOS 15, visionOS 1, *)
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
        return self
            .buttonStyle(.borderedProminent)
            .tint(Color(uiColor: .buttonBackground))
        #elseif targetEnvironment(macCatalyst)
        if #available(iOS 26, *) {
            return self.buttonStyle(.glass)
        } else {
            return self.buttonStyle(.borderedProminent)
        }
        #else
        if #available(iOS 26, *) {
            return self.buttonStyle(.glass)
        } else {
            return self
                .buttonStyle(.borderedProminent)
                .tint(Color(uiColor: .buttonBackground))
        }
        #endif
    }

    func prominentGlassButtonStyle() -> some View {
        #if os(visionOS)
        return self
            .buttonStyle(.borderedProminent)
            .tint(Color(uiColor: .buttonBackground))
        #elseif targetEnvironment(macCatalyst)
        if #available(iOS 26, *) {
            return self.buttonStyle(.glassProminent)
        } else {
            return self.buttonStyle(.borderedProminent)
        }
        #else
        if #available(iOS 26, *) {
            return self
                .buttonStyle(.glassProminent)
                .tint(Color(uiColor: .buttonBackground))
        } else {
            return self
                .buttonStyle(.borderedProminent)
                .tint(Color(uiColor: .buttonBackground))
        }
        #endif
    }
}
