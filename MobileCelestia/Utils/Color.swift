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

extension UIColor {
    class var darkSeparator: UIColor {
        if #available(iOS 13.0, *) {
            return .separator
        }
        return UIColor(rgb: 0x545458).withAlphaComponent(0.6)
    }

    class var darkLabel: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        }
        return UIColor.white
    }

    class var darkSecondaryLabel: UIColor {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        }
        return UIColor(rgb: 0xEBEBF5).withAlphaComponent(0.6)
    }

    class var darkTertiaryLabel: UIColor {
        if #available(iOS 13.0, *) {
            return .tertiaryLabel
        }
        return UIColor(rgb: 0xEBEBF5).withAlphaComponent(0.3)
    }

    class var darkSelection: UIColor {
        if UIColor.responds(to: NSSelectorFromString("tableCellPlainSelectedBackgroundColor")) {
            if let color = UIColor.value(forKey: "tableCellPlainSelectedBackgroundColor") as? UIColor {
                return color
            }
        }
        if #available(iOS 13.0, *) {
            return .systemGray4
        }
        return UIColor(rgb: 0x3A3A3C)
    }

    class var darkBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        }
        return UIColor.black
    }

    class var darkGroupedBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGroupedBackground
        }
        return UIColor.black
    }

    class var darkSecondaryBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .secondarySystemBackground
        }
        return UIColor(rgb: 0x1C1C1E)
    }

    class var darkSystemFill: UIColor {
        if #available(iOS 13.0, *) {
            return .systemFill
        }
        return UIColor(rgb: 0x787880).withAlphaComponent(0.36)
    }

    @available(iOS, introduced: 2.0, deprecated: 13.0, message: "Compatible color for iOS 12 and lower should not be used on iOS 13")
    class var darkPlainHeaderBackground: UIColor {
        return UIColor(rgb: 0x323234)
    }

    @available(iOS, introduced: 2.0, deprecated: 13.0, message: "Compatible color for iOS 12 and lower should not be used on iOS 13")
    class var darkPlainHeaderLabel: UIColor {
        return UIColor(rgb: 0xDCDCDC)
    }

    #if !targetEnvironment(macCatalyst)
    class var darkSystemBlueColor: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBlue
        }
        return UIColor(rgb: 0x0A84FF)
    }
    #endif
}

#if !targetEnvironment(macCatalyst)
extension UIColor {
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

extension UIColor {
    class var progressBackground: UIColor {
        return themeLabel.withAlphaComponent(0.38)
    }

    class var progressForeground: UIColor {
        return themeLabel
    }
}
#endif
