//
// CompatProgressButton.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class CompatProgressButton: UIView {
    private lazy var macProgressView = UIProgressView()
    private lazy var macActionButton = ActionButton(type: .system)
    private lazy var iosProgressButton = ProgressButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            macActionButton.addTarget(target, action: action, for: controlEvents)
        } else {
            iosProgressButton.addTarget(target, action: action, for: controlEvents)
        }
    }

    open func setTitle(_ title: String?, for state: UIControl.State) {
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            macActionButton.setTitle(title, for: state)
        } else {
            iosProgressButton.setTitle(title, for: state)
        }
    }

    public func resetProgress() {
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            macProgressView.setProgress(0.0, animated: false)
            macProgressView.isHidden = true
        } else {
            iosProgressButton.resetProgress()
        }
    }

    public func setProgress(progress: CGFloat) {
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            macProgressView.setProgress(Float(progress), animated: false)
            macProgressView.isHidden = false
        } else {
            iosProgressButton.setProgress(progress: progress)
        }
    }

    public func complete() {
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            macProgressView.setProgress(Float(1.0), animated: false)
            macProgressView.isHidden = true
        } else {
            iosProgressButton.setProgress(progress: 1.0)
        }
    }

    private func setUp() {
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            // Mac idiom, use progress view + action button
            let stackView = UIStackView(arrangedSubviews: [macProgressView, macActionButton])
            stackView.axis = .horizontal
            stackView.spacing = 6
            stackView.alignment = .center
            stackView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        } else {
            // iOS idiom, use progress button
            addSubview(iosProgressButton)

            iosProgressButton.contentEdgeInsets = ActionButton.Constants.contentEdgeInsets
            iosProgressButton.layer.cornerRadius = ActionButton.Constants.cornerRadius
            iosProgressButton.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                iosProgressButton.leadingAnchor.constraint(equalTo: leadingAnchor),
                iosProgressButton.trailingAnchor.constraint(equalTo: trailingAnchor),
                iosProgressButton.topAnchor.constraint(equalTo: topAnchor),
                iosProgressButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
    }
}
