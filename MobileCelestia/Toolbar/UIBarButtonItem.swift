//
// UIBarButtonItem.swift
//
// Copyright (C) 2025-present, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

final class TouchDownUpBarButtonItem: UIBarButtonItem {
    private var innerView: UIControl?
    private var eventHandlerAdded = false

    private let touchDown: () -> Void
    private let touchUp: (Bool) -> Void

    init(image: UIImage?, touchDown: @escaping () -> Void, touchUp: @escaping (Bool) -> Void) {
        self.touchDown = touchDown
        self.touchUp = touchUp

        super.init()
        self.image = image
        self.target = nil

        addObserver(self, forKeyPath: "view", options: [.initial, .new], context: nil)
    }

    deinit {
        removeObserver(self, forKeyPath: "view")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "view", object as? UIBarButtonItem == self else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        MainActor.assumeIsolated {
            let view = value(forKey: "view") as? UIControl
            if view != innerView {
                eventHandlerAdded = false
            }
            innerView = view

            if let innerView, !eventHandlerAdded {
                innerView.addAction(UIAction(handler: { [weak self] _ in
                    self?.touchDown()
                }), for: [.touchDown])
                innerView.addAction(UIAction(handler: { [weak self] _ in
                    self?.touchUp(false)
                }), for: [.touchUpOutside, .touchCancel])
                innerView.addAction(UIAction(handler: { [weak self] _ in
                    self?.touchUp(true)
                }), for: [.touchUpInside])
            }
        }
    }
}
