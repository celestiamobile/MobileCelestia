//
// StandardButton.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

open class StandardButton: UIButton {
    public let animationDuration: TimeInterval = 0.1

    public override var isHighlighted: Bool {
        get { return super.isHighlighted }
        set {
            super.isHighlighted = newValue
            UIView.animate(withDuration: animationDuration) {
                self.alpha = newValue ? 0.38 : 1
            }
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
        addInteraction(UIPointerInteraction(delegate: self))
    }
}

extension StandardButton: UIPointerInteractionDelegate {
    public func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        return defaultRegion
    }

    public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        return UIPointerStyle(effect: .highlight(UITargetedPreview(view: self)))
    }
}
