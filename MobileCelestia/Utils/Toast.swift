//
// Toast.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

@MainActor
class Toast {
    private enum Constants {
        static let toastCornerRadius: CGFloat = 8
    }

    private class View: UIView {
        lazy var label = UILabel(textStyle: .footnote)

        override init(frame: CGRect) {
            super.init(frame: frame)

            setup()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setup() {
            let style: UIBlurEffect.Style
            if #available(iOS 13.0, *) {
                style = .regular
            } else {
                style = .dark
            }
            let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)

            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: view.leadingAnchor),
                trailingAnchor.constraint(equalTo: view.trailingAnchor),
                topAnchor.constraint(equalTo: view.topAnchor),
                bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])

            label.textColor = .darkLabel
            label.numberOfLines = 2
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            view.contentView.addSubview(label)

            NSLayoutConstraint.activate([
                view.contentView.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal),
                view.contentView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
                view.contentView.topAnchor.constraint(equalTo: label.topAnchor, constant: -GlobalConstants.pageMediumMarginVertical),
                view.contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: GlobalConstants.pageMediumMarginVertical),
            ])

            layer.cornerRadius = Constants.toastCornerRadius
            layer.cornerCurve = .continuous
            clipsToBounds = true
        }
    }

    private static var sharedToast = View()
    private static var sharedTimer: Timer?

    class func show(text: String, in window: UIWindow, duration: TimeInterval) {
        sharedToast.label.text = text

        if sharedTimer == nil || sharedToast.window != window {
            sharedToast.removeFromSuperview()

            sharedToast.translatesAutoresizingMaskIntoConstraints = false
            window.addSubview(sharedToast)

            NSLayoutConstraint.activate([
                NSLayoutConstraint(item: sharedToast, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: window, attribute: .leading, multiplier: 1, constant: GlobalConstants.pageMediumMarginHorizontal),
                NSLayoutConstraint(item: sharedToast, attribute: .centerX, relatedBy: .equal, toItem: window, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: sharedToast, attribute: .centerY, relatedBy: .equal, toItem: window, attribute: .centerY, multiplier: 1.5, constant: 0)
            ])
        }

        sharedTimer?.invalidate()
        sharedTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { (timer) in
            sharedToast.removeFromSuperview()
            sharedTimer = nil
        }
    }
}
