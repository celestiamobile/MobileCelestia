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
}
