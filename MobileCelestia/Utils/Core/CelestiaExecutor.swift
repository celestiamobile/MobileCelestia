// CelestiaExecutor.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import AsyncGLANGLE
import CelestiaCore
import CelestiaUI
import Foundation

final class CelestiaExecutor: AsyncGLExecutor, AsyncProviderExecutor, @unchecked Sendable {
    let core: AppCore

    init(core: AppCore) {
        self.core = core
    }

    func runAsynchronously(_ task: @escaping @Sendable (AppCore) -> Void) {
        Task {
            runTaskAsynchronously {
                task(self.core)
            }
        }
    }

    func run(_ task: @escaping @Sendable (AppCore) -> Void) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.runTaskAsynchronously {
                task(self.core)
                continuation.resume(returning: ())
            }
        }
    }

    func get<T>(_ task: @escaping @Sendable (AppCore) -> T) async -> T {
        return await withCheckedContinuation { continuation in
            self.runTaskAsynchronously {
                continuation.resume(returning: task(self.core))
            }
        }
    }

    func receive(_ action: CelestiaAction) async {
        await run {
            $0.receive(action)
        }
    }

    func selectAndReceive(_ selection: Selection, action: CelestiaAction) async {
        await run {
            $0.simulation.selection = selection
            $0.receive(action)
        }
    }

    func charEnter(_ char: Int8) async {
        await run {
            $0.charEnter(char)
        }
    }

    var selection: Selection {
        get async {
            return await get { $0.simulation.selection }
        }
    }

    func mark(_ selection: Selection, markerType: MarkerRepresentation) async {
        await run { core in
            core.simulation.universe.mark(selection, with: markerType)
            core.showMarkers = true
        }
    }

    func setValue(_ value: Sendable?, forKey key: String) async {
        await run { core in
            core.setValue(value, forKey: key)
        }
    }
}
