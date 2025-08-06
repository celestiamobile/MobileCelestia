// UIViewController+Extension.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import UIKit

extension UIViewController {
    func getTextInputDifferentiated(_ title: String, message: String? = nil, text: String? = nil, placeholder: String? = nil, keyboardType: UIKeyboardType = .default, source: PopoverSource? = nil) async -> String? {
        return await withCheckedContinuation { continuation in
            showTextInputDifferentiated(title, message: message, text: text, placeholder: placeholder, keyboardType: keyboardType, source: source) { result in
                continuation.resume(returning: result)
            }
        }
    }

    func showTextInputDifferentiated(_ title: String, message: String? = nil, text: String? = nil, placeholder: String? = nil, keyboardType: UIKeyboardType = .default, source: PopoverSource? = nil, completion: ((String?) -> Void)? = nil) {
        #if targetEnvironment(macCatalyst)
        if let window = view.window?.nsWindow {
            MacBridge.showTextInputSheetForWindow(window, title: title, message: message, text: text, placeholder: placeholder, okButtonTitle: CelestiaString("OK", comment: ""), cancelButtonTitle: CelestiaString("Cancel", comment: "")) { result in
                completion?(result)
            }
            return
        }
        #endif
        showTextInput(title, message: message, text: text, placeholder: placeholder, keyboardType: keyboardType, source: source, completion: completion)
    }

    func getDateInputDifferentiated(_ title: String, format: String, source: PopoverSource? = nil) async -> Date? {
        return await withCheckedContinuation { continuation in
            showDateInputDifferentiated(title, format: format, source: source) { result in
                continuation.resume(returning: result)
            }
        }
    }

    func showDateInputDifferentiated(_ title: String, format: String, source: PopoverSource? = nil, completion: ((Date?) -> Void)? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        showTextInputDifferentiated(title, message: nil, text: nil, placeholder: formatter.string(from: Date()), source: source) { result in
            guard let result = result else {
                // cancelled, do not call completion
                return
            }
            completion?(formatter.date(from: result))
        }
    }
}
