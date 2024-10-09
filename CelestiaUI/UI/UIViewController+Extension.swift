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

import LinkPresentation
import UIKit

public enum PopoverSource {
    case barButtonItem(barButtonItem: UIBarButtonItem)
    case view(view: UIView, sourceRect: CGRect?)
}

public extension UIViewController {
    func install(_ child: UIViewController, safeAreaEdges: NSDirectionalRectEdge = []) {
        addChild(child)

        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)

        if safeAreaEdges.contains(.leading) {
            child.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        } else {
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        }

        if safeAreaEdges.contains(.trailing) {
            child.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        } else {
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        }

        if safeAreaEdges.contains(.top) {
            child.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            child.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        }

        if safeAreaEdges.contains(.bottom) {
            child.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }

        child.didMove(toParent: self)
    }

    func remove() {
        guard parent != nil else { return }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    func stopObservingWindowTitle() {
        _titleObservation?.invalidate()
        _titleObservation = nil
    }

    func observeWindowTitle(for viewController: UIViewController) {
        stopObservingWindowTitle()
        _titleObservation = viewController.observe(\.windowTitle, options: [.initial, .new]) { [weak self] (viewController, _) in
            Task { @MainActor in
                guard let self = self else { return }
                self.windowTitle = viewController.windowTitle
            }
        }
    }
}

private struct UIViewControllerAssociatedKeys {
    @MainActor
    static var _titleObservation: UInt8 = 0
}

fileprivate extension UIViewController {
    var _titleObservation: NSKeyValueObservation? {
        get { return objc_getAssociatedObject(self, &UIViewControllerAssociatedKeys._titleObservation) as? NSKeyValueObservation }
        set { objc_setAssociatedObject(self, &UIViewControllerAssociatedKeys._titleObservation, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

public class NavigationController: BaseNavigationController {
    override public func topViewControllerDidChange(_ viewController: UIViewController) {
        super.topViewControllerDidChange(viewController)

        observeWindowTitle(for: viewController)
    }
}

public extension UIViewController {
    var front: UIViewController? {
        guard isViewLoaded else { return nil }
        if let presented = presentedViewController { return presented.front }
        return self
    }
}

public extension UIViewController {
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
        #if targetEnvironment(macCatalyst)
        let alertStyle: UIAlertController.Style
        if options.count > 3 {
            alertStyle = .actionSheet
        } else {
            alertStyle = .alert
        }
        #else
        let alertStyle = UIAlertController.Style.actionSheet
        #endif
        let alert = UIAlertController(title: title, message: nil, preferredStyle: alertStyle)
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

    @discardableResult func showSelection(_ title: String?, options: [String], source: PopoverSource?, completion: ((Int?) -> Void)?) -> UIAlertController {
        let alert = commonSelectionActionSheet(title, options: options, completion: completion)
        presentAlert(alert, source: source)
        return alert
    }

    func presentAlert(_ alert: UIAlertController, source: PopoverSource?, completion: (() -> Void)? = nil) {
        present(alert, source: source, completion: completion)
    }

    func present(_ viewController: UIViewController, source: PopoverSource?, completion: (() -> Void)? = nil) {
        // Present from the top view controller to ensure that it can get presented correctly
        var presentingController = self
        while let viewController = presentingController.presentedViewController, !viewController.isBeingDismissed {
            presentingController = viewController
        }
        switch source {
        case .barButtonItem(let barButtonItem):
            viewController.popoverPresentationController?.barButtonItem = barButtonItem
            viewController.popoverPresentationController?.permittedArrowDirections = .any
        case .view(let view, let sourceRect):
            viewController.popoverPresentationController?.sourceView = view
            viewController.popoverPresentationController?.sourceRect = sourceRect ?? view.bounds
            viewController.popoverPresentationController?.permittedArrowDirections = .any
        case .none:
            let sourceRectRequired: Bool
            if let alert = viewController as? UIAlertController, alert.preferredStyle == .actionSheet {
                sourceRectRequired = true
            } else if viewController is UIActivityViewController {
                sourceRectRequired = true
            } else {
                sourceRectRequired = false
            }
            if sourceRectRequired {
                viewController.popoverPresentationController?.sourceView = view
                viewController.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                viewController.popoverPresentationController?.permittedArrowDirections = []
            }
        }
        presentingController.present(viewController, animated: true, completion: completion)
    }

    func getTextInput(_ title: String, message: String? = nil, text: String? = nil, placeholder: String? = nil, keyboardType: UIKeyboardType = .default, source: PopoverSource? = nil) async -> String? {
        return await withCheckedContinuation { continuation in
            showTextInput(title, message: message, text: text, placeholder: placeholder, keyboardType: keyboardType, source: source) { result in
                continuation.resume(returning: result)
            }
        }
    }

    func showTextInput(_ title: String, message: String? = nil, text: String? = nil, placeholder: String? = nil, keyboardType: UIKeyboardType = .default, source: PopoverSource? = nil, completion: ((String?) -> Void)? = nil) {
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

    func getDateInput(_ title: String, format: String, source: PopoverSource? = nil) async -> Date? {
        return await withCheckedContinuation { continuation in
            showDateInput(title, format: format, source: source) { result in
                continuation.resume(returning: result)
            }
        }
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

    func showShareSheet(for item: Any, source: PopoverSource? = nil) {
        let activityController = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        callAfterDismissCurrent(animated: true) { [weak self] in
            guard let self = self else { return }
            self.present(activityController, source: source)
        }
    }

    func callAfterDismissCurrent(animated: Bool, block: @escaping () -> Void) {
        if presentedViewController == nil || presentedViewController?.isBeingDismissed == true {
            block()
        } else {
            dismiss(animated: animated) {
                block()
            }
        }
    }

    func shareURL(_ url: String, placeholder: String) {
        let showShareFail: (String?) -> Void = { [unowned self] message in
            self.showError(CelestiaString("Cannot share URL", comment: "Failed to share a URL"), detail: message)
        }
        guard let url = URL(string: url) else {
            showShareFail(nil)
            return
        }

        class CelestiaURLObject: NSObject, UIActivityItemSource {
            func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
                return url
            }

            func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
                return url
            }

            func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
                let metadata = LPLinkMetadata()
                metadata.url = url
                metadata.title = title
                metadata.originalURL = url
                return metadata
            }

            let title: String
            let url: URL

            init(title: String, url: URL) {
                self.title = title
                self.url = url
                super.init()
            }
        }

        showShareSheet(for: CelestiaURLObject(title: placeholder, url: url))
    }
}
