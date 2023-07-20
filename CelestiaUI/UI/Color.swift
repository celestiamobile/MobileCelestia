//
// Color.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

#if !targetEnvironment(macCatalyst)
public extension UIColor {
    class var buttonBackground: UIColor {
        return UIColor(rgb: 0x404659)
    }

    class var buttonForeground: UIColor {
        return UIColor(rgb: 0xDCE1F9)
    }

    class var themeLabel: UIColor {
        return UIColor(rgb: 0xAFC6FF)
    }
}

public extension UIColor {
    class var progressBackground: UIColor {
        return themeLabel.withAlphaComponent(0.38)
    }

    class var progressForeground: UIColor {
        return themeLabel
    }
}
#endif
