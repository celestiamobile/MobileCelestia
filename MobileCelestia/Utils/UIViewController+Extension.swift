//
//  UIViewController+Extension.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/23.
//  Copyright © 2020 李林峰. All rights reserved.
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
    @discardableResult func showError(_ title: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CelestiaString("OK", comment: ""), style: .default, handler: nil))
        presentAlert(alert)
        return alert
    }

    @discardableResult func showOption(_ title: String, message: String? = nil, completion: ((Bool) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: CelestiaString("OK", comment: ""), style: .default, handler: { (_) in
            completion?(true)
        })
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: CelestiaString("Cancel", comment: ""), style: .cancel, handler: { (_) in
            completion?(false)
        }))
        alert.preferredAction = confirmAction
        presentAlert(alert)
        return alert
    }

    @discardableResult func showTextInput(_ title: String, message: String? = nil, text: String? = nil, placeholder: String? = nil, completion: ((String?) -> Void)? = nil) -> UIAlertController {
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
        presentAlert(alert)
        return alert
    }

    @discardableResult func showLoading(_ title: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        presentAlert(alert)
        return alert
    }

    private func presentAlert(_ alert: UIAlertController) {
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.frame.midX, y: view.frame.midY, width: 0, height: 0)
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        present(alert, animated: true, completion: nil)
    }
}
