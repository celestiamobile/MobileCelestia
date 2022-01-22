//
// ActionButton.swift
//
// Copyright © 2021 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class ActionButton: StandardButton {
    enum Constants {
        private static var scale: CGFloat {
            #if targetEnvironment(macCatalyst)
            return 0.77 / MacBridge.catalystScaleFactor
            #else
            return 1
            #endif
        }

        static var contentEdgeInsets: UIEdgeInsets {
            return UIEdgeInsets(top: 10 * scale, left: 0, bottom: 10 * scale, right: 0)
        }

        static var cornerRadius: CGFloat {
            return 6 * scale
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
        } else {
            titleLabel?.lineBreakMode = .byWordWrapping
            titleLabel?.textAlignment = .center
            contentEdgeInsets = Constants.contentEdgeInsets
            layer.cornerRadius = Constants.cornerRadius
            #if targetEnvironment(macCatalyst)
            backgroundColor = tintColor
            setTitleColor(.white, for: .normal)
            #else
            backgroundColor = .themeBackground
            setTitleColor(.onThemeBackground, for: .normal)
            #endif
        }
    }

    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)

        guard #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac else { return }

        if let uiNSView = subview.subviews.first,
           String(describing: type(of: uiNSView)) == "_UINSView",
           uiNSView.responds(to: NSSelectorFromString("contentNSView")) {
            let contentNSView = uiNSView.value(forKey: "contentNSView") as AnyObject
            if contentNSView.responds(to: NSSelectorFromString("setControlSize:")) {
                contentNSView.setValue(3, forKey: "controlSize")
            }
        }
    }
}
