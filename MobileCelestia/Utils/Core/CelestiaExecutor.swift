//
// CelestiaExecutor.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import AsyncGLANGLE
import CelestiaCore
import CelestiaUI
import Foundation

final class CelestiaExecutor: AsyncGLExecutor, AsyncProviderExecutor, @unchecked Sendable {
    @Injected(\.appCore) private var core

    func runAsynchronously(_ task: @escaping (AppCore) -> Void) {
        runTaskAsynchronously {
            task(self.core)
        }
    }

    func run(_ task: @escaping @Sendable (AppCore) -> Void) async {
        let core = self.core
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.runTaskAsynchronously {
                task(core)
                continuation.resume(returning: ())
            }
        }
    }

    func getSynchronously<T>(_ task: @escaping @Sendable (AppCore) -> T) -> T {
        var item: T?
        let core = self.core
        runTaskSynchronously {
            item = task(core)
        }
        guard let returnItem = item else { fatalError() }
        return returnItem
    }

    func get<T>(_ task: @escaping @Sendable (AppCore) -> T) async -> T {
        let core = self.core
        return await withCheckedContinuation { continuation in
            self.runTaskAsynchronously {
                continuation.resume(returning: task(core))
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

private struct CelestiaExecutorKey: InjectionKey {
    static var currentValue: CelestiaExecutor = CelestiaExecutor()
}

extension InjectedValues {
    var executor: CelestiaExecutor {
        get { Self[CelestiaExecutorKey.self] }
        set { Self[CelestiaExecutorKey.self] = newValue }
    }
}
