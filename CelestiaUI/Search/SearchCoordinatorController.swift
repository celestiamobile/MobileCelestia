//
// SearchCoordinatorController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

public class SearchCoordinatorController: ToolbarNavigationContainerController {
    private let executor: AsyncProviderExecutor

    private let selection: (Selection) -> SearchContentViewController

    public init(executor: AsyncProviderExecutor, selected: @escaping (Selection) -> SearchContentViewController) {
        self.selection = selected
        self.executor = executor
        super.init(rootViewController: UIViewController())
        setViewControllers([SearchViewController(executor: executor) { [weak self] parent, _, object in
            guard let self else { return }
            guard !object.isEmpty else {
                self.showError(CelestiaString("Object not found", comment: ""))
                return
            }
            let viewController = self.selection(object)
            parent.installContentViewController(viewController)
        }], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InfoViewController: SearchContentViewController {
    public var contentScrollView: UIScrollView? { return collectionView }
}
