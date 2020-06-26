//
//  StandardButton.swift
//  MobileCelestia
//
//  Created by Levin Li on 2020/6/18.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class StandardButton: UIButton {
    let animationDuration: TimeInterval = 0.1

    override var isHighlighted: Bool {
        get { return super.isHighlighted }
        set {
            super.isHighlighted = newValue
            UIView.animate(withDuration: animationDuration) {
                self.alpha = newValue ? 0.3 : 1
            }
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
        if #available(iOS 13.4, *) {
            addInteraction(UIPointerInteraction(delegate: self))
        }
    }
}

@available(iOS 13.4, *)
extension StandardButton: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        return defaultRegion
    }

    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        return UIPointerStyle(effect: .hover(.init(view: self)))
    }
}
