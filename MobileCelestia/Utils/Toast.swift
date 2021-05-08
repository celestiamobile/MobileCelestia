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

class Toast {
    private class View: UIView {
        lazy var label = UILabel()

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
            label.font = UIFont.preferredFont(forTextStyle: .footnote)
            label.numberOfLines = 2
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            view.contentView.addSubview(label)

            NSLayoutConstraint.activate([
                view.contentView.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: -16),
                view.contentView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
                view.contentView.topAnchor.constraint(equalTo: label.topAnchor, constant: -8),
                view.contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            ])

            layer.cornerRadius = 8
            if #available(iOS 13.0, *) {
                layer.cornerCurve = .continuous
            }
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
                NSLayoutConstraint(item: sharedToast, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: window, attribute: .leading, multiplier: 1, constant: 16),
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
