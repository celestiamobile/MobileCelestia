//
// AppCoreMisc.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import Foundation

private struct AppCoreKey: InjectionKey {
    static var currentValue: AppCore = AppCore()
}

extension InjectedValues {
    var appCore: AppCore {
        get { Self[AppCoreKey.self] }
        set { Self[AppCoreKey.self] = newValue }
    }
}

// MARK: Scripting
func readScripts() -> [Script] {
    var scripts = Script.scripts(inDirectory: "scripts", deepScan: true)
    if let extraScriptsPath = UserDefaults.extraScriptDirectory?.path {
        scripts += Script.scripts(inDirectory: extraScriptsPath, deepScan: true)
    }
    return scripts
}
