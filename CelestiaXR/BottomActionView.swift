// BottomActionView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import SwiftUI

struct BottomActionView: View {
    enum Action: Identifiable {
        var id: String {
            switch self {
            case .transient(let action):
                return "transient_\(action.rawValue)"
            case .continuous(let action):
                return "continuous_\(action.rawValue)"
            }
        }

        case transient(action: CelestiaAction)
        case continuous(action: CelestiaContinuousAction)

        var image: UIImage? {
            switch self {
            case .transient(let action):
                action.image
            case .continuous(let action):
                action.image
            }
        }
    }

    enum ActionGroup: Int, CaseIterable, Identifiable {
        case time
        case speed

        var id: Int {
            rawValue
        }

        var title: String {
            switch self {
            case .time:
                CelestiaString("Time", comment: "")
            case .speed:
                CelestiaString("Speed", comment: "")
            }
        }

        var actions: [Action] {
            switch self {
            case .time:
                [.transient(action: .slower), .transient(action: .playpause), .transient(action: .faster), .transient(action: .reverse)]
            case .speed:
                [.continuous(action: .travelSlower), .transient(action: .stop), .continuous(action: .travelFaster), .transient(action: .reverseSpeed)]
            }
        }
    }

    @Environment(XRRenderer.self) private var renderer
    @State private var selectedActionGroup: ActionGroup = .time

    var body: some View {
        HStack(alignment: .center) {
            Picker(String(), selection: $selectedActionGroup) {
                ForEach(ActionGroup.allCases) {
                    Text($0.title)
                        .tag($0)
                }
            }
            .pickerStyle(.segmented)

            ForEach(selectedActionGroup.actions) { action in
                if let image = action.image {
                    switch action {
                    case .transient(let action):
                        Button(action: {
                            renderer.enqueue { core in
                                core.receive(action)
                            }
                        }, label: {
                            Image(uiImage: image)
                        })
                    case .continuous(let action):
                        Button(action: {}, label: {
                            Image(uiImage: image)
                        })
                        .onLongPressGesture(minimumDuration: 0, perform: {}, onPressingChanged: { pressed in
                            renderer.enqueue { core in
                                if pressed {
                                    core.keyDown(action.rawValue)
                                } else {
                                    core.keyUp(action.rawValue)
                                }
                            }
                        })
                    }
                }
            }
        }
    }
}
