//
// UIContentSizeCategory+Extension.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public extension UITraitCollection {
    func scaledValue(for value: CGFloat) -> CGFloat {
        return UIFontMetrics.default.scaledValue(for: value, compatibleWith: self)
    }

    func scaledValue(for value: CGSize) -> CGSize {
        return CGSize(width: scaledValue(for: value.width), height: scaledValue(for: value.height))
    }

    func roundUpToPixel(_ value: CGFloat) -> CGFloat {
      return ceil(value * displayScale) / displayScale
    }

    func roundDownToPixel(_ value: CGFloat) -> CGFloat {
      return floor(value * displayScale) / displayScale
    }

    func roundUpToPixel(_ value: CGSize) -> CGSize {
        return CGSize(width: roundUpToPixel(value.width), height: roundUpToPixel(value.height))
    }

    func roundDownToPixel(_ value: CGSize) -> CGSize {
        return CGSize(width: roundDownToPixel(value.width), height: roundDownToPixel(value.height))
    }
}

public extension UITraitEnvironment {
    func scaledValue(for value: CGFloat) -> CGFloat {
        return traitCollection.scaledValue(for: value)
    }

    func scaledValue(for value: CGSize) -> CGSize {
        return traitCollection.scaledValue(for: value)
    }

    func roundUpToPixel(_ value: CGFloat) -> CGFloat {
        return traitCollection.roundUpToPixel(value)
    }

    func roundDownToPixel(_ value: CGFloat) -> CGFloat {
        return traitCollection.roundDownToPixel(value)
    }

    func roundUpToPixel(_ value: CGSize) -> CGSize {
        return traitCollection.roundUpToPixel(value)
    }

    func roundDownToPixel(_ value: CGSize) -> CGSize {
        return traitCollection.roundDownToPixel(value)
    }
}
