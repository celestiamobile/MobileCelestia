// XRRenderer.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaUI
import CelestiaXRCore
import CompositorServices
import Foundation
import Spatial
import SwiftUI

extension Renderer: @unchecked @retroactive Sendable {}
extension RendererStatus: @unchecked @retroactive Sendable {}
extension AppState: @unchecked @retroactive Sendable {}

final class SystemAccessRequest: NSObject, @unchecked Sendable {
    var granted: Bool
    let dispatchGroup: DispatchGroup

    init(granted: Bool, dispatchGroup: DispatchGroup) {
        self.granted = granted
        self.dispatchGroup = dispatchGroup
    }
}

@MainActor
@Observable final class XRRenderer: NSObject, AppCoreDelegate {
    @ObservationIgnored
    private let renderer: Renderer

    @ObservationIgnored
    let appCore: AppCore

    private(set) var rendererStatus: RendererStatus
    private(set) var currentFileName: String?
    private(set) var state: AppState?
    private(set) var selection: Selection
    private(set) var message: String

    var alertMessage: String?
    var systemAccessRequest: SystemAccessRequest?

    @ObservationIgnored
    private var eventFocusDirection: Vector3D?

    @ObservationIgnored
    private var previousEvents: [SpatialEventCollection.Event.ID: SpatialEventCollection.Event] = [:]

    init(renderer: Renderer) {
        self.renderer = renderer
        appCore = renderer.appCore
        rendererStatus = .none
        currentFileName = nil
        selection = Selection()
        message = ""

        super.init()

        appCore.delegate = self
        registerListeners()
    }

    private nonisolated func registerListeners() {
        renderer.fileNameUpdater = { [weak self] newFileName in
            guard let self else { return }
            Task.detached { @MainActor in
                self.currentFileName = newFileName
            }
        }

        renderer.statusUpdater = { [weak self] newStatus in
            guard let self else { return }
            Task { @MainActor in
                self.rendererStatus = newStatus
            }
        }

        renderer.stateUpdater = { [weak self] newState in
            guard let self else { return }
            Task { @MainActor in
                self.state = newState
                let selection = newState.selectedObject
                if self.selection != selection {
                    self.selection = selection
                }
            }
        }

        renderer.messageUpdater = { [weak self] message in
            guard let self else { return }
            Task { @MainActor in
                self.message = message
            }
        }
    }

    func enqueue(events: SpatialEventCollection) {
        guard !events.isEmpty else { return }

        let before = previousEvents
        for event in events {
            previousEvents[event.id] = event
        }
        let after = previousEvents
        for event in events {
            if event.phase != .active {
                previousEvents[event.id] = nil
            }
        }

        var processedEvent: InputEvent?

        // Event type change, when the number of touches change
        let eventChangedOrEnded = before.count != previousEvents.count
        if let eventFocusDirection, before.count == after.count {
            let beforeEvents = Array(before.values)
            switch beforeEvents.count {
            case 1:
                let old = beforeEvents[0]
                if let oldDevicePose = old.inputDevicePose,
                   let newDevicePose = after[old.id]?.inputDevicePose {
                    processedEvent = SingleTouchInputEvent(oldPose: oldDevicePose.pose3D, newPose: newDevicePose.pose3D, focus: eventFocusDirection, phase: eventChangedOrEnded ? .ended : .active)
                }
            case 2:
                let old1 = beforeEvents[0]
                let old2 = beforeEvents[1]
                if let oldPosition1 = old1.inputDevicePose?.pose3D.position,
                   let oldPosition2 = old2.inputDevicePose?.pose3D.position,
                   let newPosition1 = after[old1.id]?.inputDevicePose?.pose3D.position,
                   let newPosition2 = after[old2.id]?.inputDevicePose?.pose3D.position {
                    processedEvent = DoubleTouchInputEvent(oldPosition1: oldPosition1, oldPosition2: oldPosition2, newPosition1: newPosition1, newPosition2: newPosition2, focus: eventFocusDirection, phase: eventChangedOrEnded ? .ended : .active)
                }
                break
            default:
                break
            }
        }

        if eventChangedOrEnded {
            if before.count > previousEvents.count {
                eventFocusDirection = nil
            } else {
                eventFocusDirection = events.first?.selectionRay?.direction
            }
        }

        if let processedEvent {
            renderer.enqueue([processedEvent])
        }
    }

    nonisolated func enqueue(task: @escaping @Sendable (AppCore) -> Void) {
        renderer.enqueueTask(task)
    }

    func prepare() {
        renderer.prepare()
    }

    func startRendering(with layerRenderer: LayerRenderer) {
        renderer.startRendering(withLayerRenderer: layerRenderer)
    }

    func updateImmersionStyle(useMixedImmersion: Bool) {
        renderer.enqueueTask { [weak self] _ in
            guard let self else { return }
            renderer.useMixedImmersion = useMixedImmersion
        }
    }

    nonisolated func celestiaAppCoreCursorShapeChanged(_ shape: CursorShape) {}

    nonisolated func celestiaAppCoreFatalErrorHappened(_ error: String) {
        Task { @MainActor in
            alertMessage = error
        }
    }

    nonisolated func celestiaAppCoreRequestSystemAccess() -> Bool {
        let dispatchGroup = DispatchGroup()
        let request = SystemAccessRequest(granted: false, dispatchGroup: dispatchGroup)
        dispatchGroup.enter()
        Task { @MainActor in
            self.systemAccessRequest = request
        }
        dispatchGroup.wait()
        return request.granted
    }

    nonisolated func celestiaAppCoreWatchedFlagsDidChange(_ changedFlags: WatcherFlags) {}
}

extension XRRenderer: AsyncProviderExecutor {
    nonisolated func runAsynchronously(_ task: @escaping @Sendable (AppCore) -> Void) {
        enqueue { appCore in
            task(appCore)
        }
    }
}
