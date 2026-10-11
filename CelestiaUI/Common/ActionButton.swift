// ActionButton.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

#if targetEnvironment(macCatalyst)
public class ActionButton: StandardButton {
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
}
#endif

@MainActor
public class ActionButtonHelper {
    public static func newButton(liquidGlass: Bool = true, clear: Bool = false, prominent: Bool = false) -> UIButton {
        #if !os(visionOS)
        if #available(iOS 26, *), liquidGlass {
            let button = UIButton(configuration: prominent ? .prominentGlass() : (clear ? .clearGlass() : .glass()))
            return button
        }
        #endif
        #if !targetEnvironment(macCatalyst)
        let configuration = UIButton.Configuration.filled()
        let button = UIButton(configuration: configuration)
        button.pointerStyleProvider = { button, _, _ in
            return UIPointerStyle(effect: .highlight(UITargetedPreview(view: button)))
        }
        return button
        #else
        let button = ActionButton(type: .system)
        if #available(iOS 17, *) {
            button.traitOverrides.toolbarItemPresentationSize = .large
        }
        return button
        #endif
    }
}
