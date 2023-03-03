//
// GoToObjectView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import SwiftUI

private class GoToState: ObservableObject {
    private static var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    @Published var objectName: String = LocalizedString("Earth", "celestia-data")
    @Published var longitudeString: String = GoToState.numberFormatter.string(from: 0.0) ?? ""
    @Published var latitudeString: String = GoToState.numberFormatter.string(from: 0.0) ?? ""
    @Published var distanceString: String = GoToState.numberFormatter.string(from: 8.0) ?? ""
    @Published var distanceUnit: DistanceUnit = .radii

    var longitude: Float? {
        return Self.numberFormatter.number(from: longitudeString)?.floatValue
    }

    var latitude: Float? {
        return Self.numberFormatter.number(from: latitudeString)?.floatValue
    }

    var distance: Double? {
        return Self.numberFormatter.number(from: distanceString)?.doubleValue
    }
}

@available(iOS 16.0, *)
struct GoToObjectView: View {
    private enum Search: Hashable {
        case instance
    }

    @StateObject private var state = GoToState()

    @State private var showingAlert = false
    @State private var navigationPath = NavigationPath()

    var executor: CelestiaExecutor
    var core: AppCore
    var locationHandler: (GoToLocation) -> Void

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Form {
                Section {
                    NavigationLink(value: Search.instance) {
                        HStack {
                            Text(CelestiaString("Object", comment: ""))
                            Spacer()
                            Text(state.objectName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section(CelestiaString("Coordinates", comment: "")) {
                    VStack {
                        HStack {
                            Text(CelestiaString("Longitude", comment: ""))
                                .foregroundColor(.secondary)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(CelestiaString("Latitude", comment: ""))
                                .foregroundColor(.secondary)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        HStack {
                            TextField("", text: $state.longitudeString)
                                .frame(maxWidth: .infinity)
                            TextField("" ,text: $state.latitudeString)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                Section(CelestiaString("Distance", comment: "")) {
                    HStack {
                        TextField("", text: $state.distanceString)
                            .frame(maxWidth: .infinity)
                            .layoutPriority(1)
                        Picker(selection: $state.distanceUnit) {
                            ForEach(DistanceUnit.allCases, id: \.self) { unit in
                                Text(CelestiaString(unit.name, comment: ""))
                            }
                        } label: {
                            EmptyView()
                        }
                        .labelsHidden()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CelestiaString("Go", comment: "")) {
                        guard let longitude = state.longitude, let latitude = state.latitude, let distance = state.distance else { return }
                        let unit = state.distanceUnit
                        let name = state.objectName
                        Task {
                            let location = await executor.get { core -> GoToLocation? in
                                let selection = core.simulation.findObject(from: name)
                                if selection.isEmpty { return nil }
                                return GoToLocation(selection: selection, longitude: longitude, latitude: latitude, distance: distance, unit: unit)
                            }
                            if let location {
                                locationHandler(location)
                            } else {
                                showingAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle(CelestiaString("Go to Object", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Search.self) { _ in
                ObjectSearchView(executor: executor) { nameSelection in
                    Button(action: {
                        navigationPath.removeLast()
                        state.objectName = nameSelection.name
                    }) {
                        Text(nameSelection.name)
                    }
                    .foregroundColor(.primary)
                } submitAction: { nameSelection in
                    navigationPath.removeLast()
                    state.objectName = nameSelection.name
                }
                .navigationTitle(CelestiaString("Search", comment: ""))
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(CelestiaString("Object not found", comment: "")))
        }
    }
}

