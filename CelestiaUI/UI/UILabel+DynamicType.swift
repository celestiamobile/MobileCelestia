//
// UILabel+DynamicType.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public extension UILabel {
    convenience init(textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil) {
        self.init()
        let labelFont: UIFont
        if let weight = weight {
            labelFont = .preferredFont(forTextStyle: textStyle, weight: weight)
        } else {
            labelFont = .preferredFont(forTextStyle: textStyle)
        }
        font = labelFont
        adjustsFontForContentSizeCategory = true
    }
}
