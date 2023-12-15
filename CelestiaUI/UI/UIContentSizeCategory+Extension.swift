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

public extension UIContentSizeCategory {
    var textScaling: CGFloat {
        return UIFont.preferredFont(forTextStyle: .body, compatibleWith: UITraitCollection(preferredContentSizeCategory: self)).pointSize / UIFont.preferredFont(forTextStyle: .body, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium)).pointSize
    }
}

public extension UITraitCollection {
    var textScaling: CGFloat {
        return UIFont.preferredFont(forTextStyle: .body, compatibleWith: self).pointSize / UIFont.preferredFont(forTextStyle: .body, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium)).pointSize
    }
}

public extension UIView {
    var textScaling: CGFloat {
        return traitCollection.textScaling
    }
}
