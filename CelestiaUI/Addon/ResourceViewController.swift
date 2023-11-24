//
// ResourceViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public class ResourceViewController: ToolbarNavigationContainerController {
    private let executor: AsyncProviderExecutor
    private let resourceManager: ResourceManager
    private let actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?

    public init(executor: AsyncProviderExecutor, resourceManager: ResourceManager, actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?, getAddonHandler: @escaping () -> Void) {
        self.executor = executor
        self.resourceManager = resourceManager
        self.actionHandler = actionHandler
        super.init(rootViewController: UIViewController())
        setViewControllers([
            InstalledResourceViewController(resourceManager: resourceManager, selection: { [weak self] item in
                self?.viewItem(item)
            }, getAddonsHandler: getAddonHandler)
        ], animated: false)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ResourceViewController {
    private func viewItem(_ item: ResourceItem) {
        pushViewController(ResourceItemViewController(executor: executor, resourceManager: resourceManager, item: item, needsRefetchItem: true, actionHandler: actionHandler), animated: true)
    }
}
