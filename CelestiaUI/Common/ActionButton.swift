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

public class ActionButton: StandardButton {
    public enum Constants {
        static func contentEdgeInsets(for traitCollection: UITraitCollection) -> UIEdgeInsets {
            let scale = GlobalConstants.preferredUIElementScaling(for: traitCollection)
            let vertical = traitCollection.roundUpToPixel(10 * scale)
            return UIEdgeInsets(top: vertical, left: 0, bottom: vertical, right: 0)
        }

        static func cornerRadius(for traitCollection: UITraitCollection) -> CGFloat {
            return traitCollection.roundUpToPixel(6 * GlobalConstants.preferredUIElementScaling(for: traitCollection))
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    private func setup() {
        if #available(iOS 14, *), traitCollection.userInterfaceIdiom == .mac {
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
    public override func tintColorDidChange() {
        super.tintColorDidChange()

        if #available(iOS 14, *), traitCollection.userInterfaceIdiom == .mac {
        } else {
            backgroundColor = tintColor
        }
    }
    #endif

    public override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)

        guard #available(iOS 14, *), traitCollection.userInterfaceIdiom == .mac else { return }

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

@MainActor
public class ActionButtonHelper {
    public static func newButton() -> UIButton {
        #if !targetEnvironment(macCatalyst)
        if #available(iOS 15, visionOS 1, *) {
            var configuration = UIButton.Configuration.filled()
            configuration.baseBackgroundColor = .buttonBackground
            configuration.baseForegroundColor = .buttonForeground
            let button = UIButton(configuration: configuration)
            button.pointerStyleProvider = { button, _, _ in
                return UIPointerStyle(effect: .highlight(UITargetedPreview(view: button)))
            }
            return button
        }
        #endif
        return ActionButton(type: .system)
    }
}
