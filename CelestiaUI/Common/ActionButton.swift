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
#if !targetEnvironment(macCatalyst)
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

        setUp()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        setUp()
    }

    private func setUp() {
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center
        contentEdgeInsets = Constants.contentEdgeInsets(for: traitCollection)
        layer.cornerRadius = Constants.cornerRadius(for: traitCollection)
        layer.cornerCurve = .continuous
        backgroundColor = .buttonBackground
        setTitleColor(.buttonForeground, for: .normal)
    }
#else
    public override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)

        if #available(iOS 17, *) {
        } else {
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
#endif
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
        let button = ActionButton(type: .system)
        #if targetEnvironment(macCatalyst)
        if #available(iOS 17, *) {
            button.traitOverrides.toolbarItemPresentationSize = .large
        }
        #endif
        return button
    }
}
