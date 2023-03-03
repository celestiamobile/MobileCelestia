//
// ObjectSearchView.swift
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

private class SearchState: ObservableObject {
    var isResultUpdatedInBackground = false
    var hasDisappeared = false
    var savedCompletions: [NameSelection] = []

    @Published var searchText: String = ""
    @Published var completions: [NameSelection] = []
}

struct NameSelection: Hashable {
    let name: String
    let selection: Selection
}

@available(iOS 15.0, *)
struct ObjectSearchView<RowView: View>: View {
    @StateObject private var state = SearchState()

    var executor: CelestiaExecutor
    var selection: Binding<NameSelection?>?

    var content: (NameSelection) -> RowView
    var submitAction: (NameSelection) -> Void

    var body: some View {
        List(state.completions, id: \.self, selection: selection) { value in
            content(value)
        }
#if targetEnvironment(macCatalyst)
        .searchable(text: $state.searchText)
#else
        .searchable(text: $state.searchText, placement: .navigationBarDrawer(displayMode: .always))
#endif
        .onSubmit(of: .search) {
            Task {
                let name = state.searchText
                let selection = await executor.get { core in NameSelection(name: name, selection: core.simulation.findObject(from: name)) }
                submitAction(selection)
            }
        }
        .onChange(of: state.searchText) { newValue in
            Task {
                let newCompletions = newValue.isEmpty ? [] : await executor.get { core in return core.simulation.completion(for: newValue).map {
                    NameSelection(name: $0, selection: core.simulation.findObject(from: $0))
                }}
                if state.hasDisappeared {
                    state.savedCompletions = newCompletions
                    state.isResultUpdatedInBackground = true
                } else {
                    state.completions = newCompletions
                }
            }
        }
        .onAppear {
            if state.hasDisappeared {
                state.hasDisappeared = false
                if state.isResultUpdatedInBackground {
                    state.isResultUpdatedInBackground = false
                    state.completions = state.savedCompletions
                    state.savedCompletions = []
                }
            }
        }
        .onDisappear {
            state.hasDisappeared = true
        }
    }
}
