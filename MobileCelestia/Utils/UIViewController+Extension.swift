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

import UIKit

public extension UIViewController {
    func install(_ child: UIViewController) {
        addChild(child)

        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)

        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        child.didMove(toParent: self)
    }

    func remove() {
        guard parent != nil else { return }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

extension UIViewController {
    var front: UIViewController? {
        guard isViewLoaded else { return nil }
        if let presented = presentedViewController { return presented.front }
        return self
    }
}

extension UIViewController {
    @discardableResult func showError(_ title: String, detail: String? = nil, source: PopoverSource? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: detail, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CelestiaString("OK", comment: ""), style: .default, handler: nil))
        presentAlert(alert, source: source)
        return alert
    }

    @discardableResult func showOption(_ title: String, message: String? = nil, source: PopoverSource? = nil, completion: ((Bool) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: CelestiaString("OK", comment: ""), style: .default, handler: { (_) in
            completion?(true)
        })
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: CelestiaString("Cancel", comment: ""), style: .cancel, handler: { (_) in
            completion?(false)
        }))
        alert.preferredAction = confirmAction
        presentAlert(alert, source: source)
        return alert
    }

    @discardableResult func showTextInput(_ title: String, message: String? = nil, text: String? = nil, placeholder: String? = nil, source: PopoverSource? = nil, completion: ((String?) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: CelestiaString("OK", comment: ""), style: .default, handler: { [unowned alert] (_) in
            completion?(alert.textFields?.first?.text)
        })
        alert.addTextField { (textField) in
            textField.text = text
            textField.placeholder = placeholder
            textField.keyboardAppearance = .dark
        }
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: CelestiaString("Cancel", comment: ""), style: .cancel, handler: { (_) in
            completion?(nil)
        }))
        alert.preferredAction = confirmAction
        presentAlert(alert, source: source)
        return alert
    }

    @discardableResult func showDateInput(_ title: String, format: String, source: PopoverSource? = nil, completion: ((Date?) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let formatter = DateFormatter()
        formatter.dateFormat = format
        let confirmAction = UIAlertAction(title: CelestiaString("OK", comment: ""), style: .default, handler: { [unowned alert] _ in
            guard let text = alert.textFields?.first?.text else { return }
            completion?(formatter.date(from: text))
        })
        alert.addTextField { textField in
            textField.keyboardAppearance = .dark
            textField.placeholder = formatter.string(from: Date())
        }
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: CelestiaString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.preferredAction = confirmAction
        presentAlert(alert, source: source)
        return alert
    }

    @discardableResult func showLoading(_ title: String, source: PopoverSource? = nil, cancelHandelr: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        if let cancel = cancelHandelr {
            alert.addAction(UIAlertAction(title: CelestiaString("Cancel", comment: ""), style: .cancel) { _ in
                cancel()
            })
        }
        presentAlert(alert, source: source)
        return alert
    }

    private func commonSelectionActionSheet(_ title: String?, options: [String], permittedArrowDirections: UIPopoverArrowDirection = .any, completion: ((Int?) -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for (index, option) in options.enumerated() {
            alert.addAction(UIAlertAction(title: option, style: .default) { _ in
                completion?(index)
            })
        }
        alert.addAction(UIAlertAction(title: CelestiaString("Cancel", comment: ""), style: .cancel, handler: { _ in
            completion?(nil)
        }))
        alert.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        return alert
    }

    enum PopoverSource {
        case barButtonItem(barButtonItem: UIBarButtonItem)
        case view(view: UIView, sourceRect: CGRect?)
    }

    @discardableResult func showSelection(_ title: String?, options: [String], source: PopoverSource?, completion: ((Int?) -> Void)?) -> UIAlertController {
        let alert = commonSelectionActionSheet(title, options: options, completion: completion)
        presentAlert(alert, source: source)
        return alert
    }

    private func presentAlert(_ alert: UIAlertController, source: PopoverSource?, completion: (() -> Void)? = nil) {
        switch source {
        case .barButtonItem(let barButtonItem):
            alert.popoverPresentationController?.barButtonItem = barButtonItem
            alert.popoverPresentationController?.permittedArrowDirections = .any
        case .view(let view, let sourceRect):
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = sourceRect ?? view.bounds
            alert.popoverPresentationController?.permittedArrowDirections = .any
        case .none:
            if alert.preferredStyle == .actionSheet {
                alert.popoverPresentationController?.sourceView = view
                alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                alert.popoverPresentationController?.permittedArrowDirections = []
            }
        }
        present(alert, animated: true, completion: nil)
    }
}
