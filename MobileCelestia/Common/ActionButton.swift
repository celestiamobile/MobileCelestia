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
        static func contentEdgeInsets(for traitCollection: UITraitCollection) -> UIEdgeInsets {
            let scale = GlobalConstants.preferredUIElementScaling(for: traitCollection)
            return UIEdgeInsets(top: 10 * scale, left: 0, bottom: 10 * scale, right: 0)
        }

        static func cornerRadius(for traitCollection: UITraitCollection) -> CGFloat {
            return 6 * GlobalConstants.preferredUIElementScaling(for: traitCollection)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    private func setup() {
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
        } else {
            titleLabel?.lineBreakMode = .byWordWrapping
            titleLabel?.textAlignment = .center
            contentEdgeInsets = Constants.contentEdgeInsets(for: traitCollection)
            layer.cornerRadius = Constants.cornerRadius(for: traitCollection)
            layer.cornerCurve = .continuous
            #if targetEnvironment(macCatalyst)
            backgroundColor = tintColor
            setTitleColor(.white, for: .normal)
            #else
            backgroundColor = .buttonBackground
            setTitleColor(.buttonForeground, for: .normal)
            #endif
        }
    }

    #if targetEnvironment(macCatalyst)
    override func tintColorDidChange() {
        super.tintColorDidChange()

        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
        } else {
            backgroundColor = tintColor
        }
    }
    #endif

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

class ActionButtonHelper {
    static func newButton() -> UIButton {
        #if !targetEnvironment(macCatalyst)
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.filled()
            configuration.baseBackgroundColor = .buttonBackground
            configuration.baseForegroundColor = .buttonForeground
            return UIButton(configuration: configuration)
        }
        #endif
        return ActionButton(type: .system)
    }
}
