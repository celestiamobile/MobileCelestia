//
// AssetProvider.swift
//
// Copyright © 2025 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public enum AssetImage {
    case loadingIcon
    case browserTabDso
    case browserTabSso
    case browserTabStar
    case tutorialSwitchMode
}

@MainActor
public protocol AssetProvider {
    func image(for image: AssetImage) -> UIImage
}
