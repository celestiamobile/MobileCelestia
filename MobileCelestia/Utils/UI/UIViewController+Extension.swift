//
// UIViewController+Extension.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import UIKit

extension UIViewController {
    func showTextInput(_ title: String, message: String? = nil, text: String? = nil, placeholder: String? = nil, keyboardType: UIKeyboardType = .default, source: PopoverSource? = nil, completion: ((String?) -> Void)? = nil) {
        #if targetEnvironment(macCatalyst)
        if let window = view.window?.nsWindow {
            MacBridge.showTextInputSheetForWindow(window, title: title, message: message, text: text, placeholder: placeholder, okButtonTitle: CelestiaString("OK", comment: ""), cancelButtonTitle: CelestiaString("Cancel", comment: "")) { result in
                completion?(result)
            }
            return
        }
        #endif
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: CelestiaString("OK", comment: ""), style: .default, handler: { [unowned alert] (_) in
            completion?(alert.textFields?.first?.text ?? "")
        })
        alert.addTextField { (textField) in
            textField.text = text
            textField.placeholder = placeholder
            textField.keyboardAppearance = .dark
            textField.keyboardType = keyboardType
        }
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: CelestiaString("Cancel", comment: ""), style: .cancel, handler: { (_) in
            completion?(nil)
        }))
        alert.preferredAction = confirmAction
        presentAlert(alert, source: source)
    }

    func showDateInput(_ title: String, format: String, source: PopoverSource? = nil, completion: ((Date?) -> Void)? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        showTextInput(title, message: nil, text: nil, placeholder: formatter.string(from: Date()), source: source) { result in
            guard let result = result else {
                // cancelled, do not call completion
                return
            }
            completion?(formatter.date(from: result))
        }
    }
}
