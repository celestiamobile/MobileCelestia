//
// ContainerNavigationController.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

#if targetEnvironment(macCatalyst)
public class ContentNavigationController: UINavigationController {}

@available(macCatalyst 16, *)
extension ContentNavigationController: UINavigationBarDelegate {
    public func navigationBarNSToolbarSection(_ navigationBar: UINavigationBar) -> UINavigationBar.NSToolbarSection {
        return .content
    }
}

@available(macCatalyst 16, *)
public class SidebarNavigationController: UINavigationController {}

@available(macCatalyst 16, *)
extension SidebarNavigationController: UINavigationBarDelegate {
    public func navigationBarNSToolbarSection(_ navigationBar: UINavigationBar) -> UINavigationBar.NSToolbarSection {
        return .sidebar
    }
}
#else
typealias ContentNavigationController = UINavigationController
#endif
