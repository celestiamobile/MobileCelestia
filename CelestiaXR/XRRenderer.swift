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
import CelestiaUI
import CelestiaXRCore
import CompositorServices
import Foundation
import SwiftUI

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
            Task.detached { @MainActor in
                self.currentFileName = newFileName
            }
        }

        renderer.statusUpdater = { [weak self] newStatus in
            guard let self else { return }
            Task.detached { @MainActor in
                self.rendererStatus = newStatus
            }
        }

        renderer.selectionUpdater = { [weak self] newSelection in
            guard let self else { return }
            Task.detached { @MainActor in
                self.selection = newSelection
            }
        }
    }

    func enqueue(events: SpatialEventCollection) {
        let mapped = events.map { event in
            let phase: InputEventPhase
            switch event.phase {
            case .active:
                phase = .active
            case .cancelled:
                phase = .cancelled
            case .ended:
                phase = .ended
            @unknown default:
                phase = .cancelled
            }
            return InputEvent(location: event.location, location3D: event.location3D, selectionRay: event.selectionRay ?? Ray3D(origin: .zero, direction: .zero), phase: phase)
        }
        renderer.enqueue(mapped)
    }

    func enqueue(task: @escaping (AppCore) -> Void) {
        renderer.enqueueTask(task)
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

extension XRRenderer: AsyncProviderExecutor {
    func run(_ task: @escaping @Sendable (AppCore) -> Void) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            enqueue { appCore in
                task(appCore)
                continuation.resume()
            }
        }
    }
    
    func get<T>(_ task: @escaping @Sendable (AppCore) -> T) async -> T {
        return await withCheckedContinuation { continuation in
            enqueue { appCore in
                let result = task(appCore)
                continuation.resume(returning: result)
            }
        }
    }
}
