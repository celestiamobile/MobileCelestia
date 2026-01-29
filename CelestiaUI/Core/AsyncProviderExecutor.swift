// AsyncProviderExecutor.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import Foundation

public protocol AsyncProviderExecutor: Sendable {
    var appCore: AppCore { get }
    func runAsynchronously(_ task: @escaping @Sendable (AppCore) -> Void)
}

public extension AsyncProviderExecutor {
    func run(_ task: @escaping @Sendable (AppCore) -> Void) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.runAsynchronously {
                task($0)
                continuation.resume(returning: ())
            }
        }
    }

    func get<T>(_ task: @escaping @Sendable (AppCore) -> T) async -> T {
        return await withCheckedContinuation { continuation in
            self.runAsynchronously {
                continuation.resume(returning: task($0))
            }
        }
    }
}

@globalActor public actor CelestiaActor: GlobalActor {
    static public let shared = CelestiaActor()
    static public var underlyingExecutor: AsyncProviderExecutor? {
        get { CelestiaSerialExecutor.shared.underlyingExecutor }
        set { CelestiaSerialExecutor.shared.underlyingExecutor = newValue }
    }

    static public var appCore: AppCore {
        guard let underlyingExecutor else {
            fatalError("underlyingExecutor is not set on CelestiaSerialExecutor")
        }
        return underlyingExecutor.appCore
    }

    nonisolated public var unownedExecutor: UnownedSerialExecutor {
        CelestiaSerialExecutor.shared.asUnownedSerialExecutor()
    }
}

final class CelestiaSerialExecutor: SerialExecutor, @unchecked Sendable {
    static let shared: CelestiaSerialExecutor = CelestiaSerialExecutor()
    nonisolated(unsafe) var underlyingExecutor: AsyncProviderExecutor?

    func enqueue(_ job: UnownedJob) {
        guard let underlyingExecutor else {
            fatalError("underlyingExecutor is not set on CelestiaSerialExecutor")
        }
        underlyingExecutor.runAsynchronously { _ in
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        return UnownedSerialExecutor(ordinary: self)
    }
}
