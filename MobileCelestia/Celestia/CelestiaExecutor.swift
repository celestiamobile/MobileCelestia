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

import AsyncGL
import CelestiaCore
import Foundation

extension AppCore {
    func receive(_ action: CelestiaAction) {
        if textEnterMode != .normal {
            textEnterMode = .normal
        }
        charEnter(action.rawValue)
    }
}

final class CelestiaExecutor: AsyncGLExecutor {
    @Injected(\.appCore) private var core

    func run(_ task: @escaping (AppCore) -> Void) {
        runTaskAsynchronously {
            task(self.core)
        }
    }

    func get<T>(_ task: (AppCore) -> T) -> T {
        var item: T?
        runTaskSynchronously {
            item = task(core)
        }
        guard let returnItem = item else { fatalError() }
        return returnItem
    }

    func receiveAsync(_ action: CelestiaAction, completion: (() -> Void)? = nil) {
        run {
            $0.receive(action)
            completion?()
        }
    }

    func selectAndReceiveAsync(_ selection: Selection, action: CelestiaAction) {
        run {
            $0.simulation.selection = selection
            $0.receive(action)
        }
    }

    func charEnterAsync(_ char: Int8) {
        run {
            $0.charEnter(char)
        }
    }

    func getSelectionAsync(_ completion: @escaping (Selection, AppCore) -> Void) {
        run { core in
            completion(core.simulation.selection, core)
        }
    }

    func markAsync(_ selection: Selection, markerType: MarkerRepresentation) {
        run { core in
            core.simulation.universe.mark(selection, with: markerType)
            core.showMarkers = true
        }
    }

    func setValueAsync(_ value: Any?, forKey key: String, completionOnMainQueue: (() -> Void)? = nil) {
        run { core in
            core.setValue(value, forKey: key)
            DispatchQueue.main.async {
                completionOnMainQueue?()
            }
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
