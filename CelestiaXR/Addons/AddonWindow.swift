//
// AddonWindow.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import CelestiaUI
import MWRequest
import SwiftUI

struct AddonWindow: View {
    let id: String
    let resourceManager: ResourceManager
    let requestHandler: RequestHandler

    @State var state: LoadingState = .idle

    enum LoadingState {
        case idle
        case loading
        case failed(error: Error)
        case loaded(item: ResourceItem)
    }

    var body: some View {
        switch state {
        case .idle:
            Color.clear.onAppear {
                Task {
                    await load()
                }
            }
        case .loading:
            ProgressView()
        case let .failed(error):
            ContentUnavailableView {
                Text(error.localizedDescription)
            }
        case let .loaded(item):
            AddonView(resourceManager: resourceManager, requestHandler: requestHandler, item: item)
        }
    }

    @MainActor
    private func load() async {
        state = .loading
        do {
            let item = try await requestHandler.getMetadata(id: id, language: AppCore.language)
            state = .loaded(item: item)
        } catch {
            state = .failed(error: error)
        }
    }
}
