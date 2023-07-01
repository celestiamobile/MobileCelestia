//
// XRRenderer.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import CelestiaXRCore
import CompositorServices
import Foundation

class XRRenderer: ObservableObject {
    private var renderer: Renderer

    lazy var appCore = renderer.appCore

    @Published var rendererStatus: RendererStatus
    @Published var currentFileName: String?
    @Published var selection: Selection

    init(renderer: Renderer) {
        self.renderer = renderer
        rendererStatus = .none
        currentFileName = nil
        selection = Selection()

        registerListeners()
    }

    private func registerListeners() {
        renderer.fileNameUpdater = { [weak self] newFileName in
            guard let self else { return }
            Task { @MainActor in
                self.currentFileName = newFileName
            }
        }

        renderer.statusUpdater = { [weak self] newStatus in
            guard let self else { return }
            Task { @MainActor in
                self.rendererStatus = newStatus
            }
        }

        renderer.selectionUpdater = { [weak self] newSelection in
            guard let self else { return }
            Task { @MainActor in
                self.selection = newSelection
            }
        }
    }

    func updateRenderer() {
        renderer = Renderer(renderer: renderer)
        rendererStatus = .none
        registerListeners()
    }

    func prepare() {
        renderer.prepare()
    }

    func startRendering(with layerRenderer: LayerRenderer) {
        renderer.startRendering(withLayerRenderer: layerRenderer)
    }
}
