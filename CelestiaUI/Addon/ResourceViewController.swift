// ResourceViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

public class ResourceViewController: ToolbarNavigationContainerController {
    private let executor: AsyncProviderExecutor
    private let resourceManager: ResourceManager
    private let actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?
    private let requestHandler: RequestHandler

    public init(executor: AsyncProviderExecutor, resourceManager: ResourceManager, requestHandler: RequestHandler, actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?, getAddonHandler: @escaping () -> Void) {
        self.executor = executor
        self.resourceManager = resourceManager
        self.actionHandler = actionHandler
        self.requestHandler = requestHandler
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
        pushViewController(ResourceItemViewController(executor: executor, resourceManager: resourceManager, item: item, requestHandler: requestHandler, actionHandler: actionHandler), animated: true)
    }
}
