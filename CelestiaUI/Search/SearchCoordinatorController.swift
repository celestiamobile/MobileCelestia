// SearchCoordinatorController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

public class SearchCoordinatorController: ToolbarNavigationContainerController {
    private let executor: AsyncProviderExecutor

    private let selection: (Selection) -> SearchContentViewController

    #if !targetEnvironment(macCatalyst)
    public var searchActivationHandler: (() -> Void)?
    #endif

    public init(executor: AsyncProviderExecutor, initialSearchTerm: String? = nil, selected: @escaping (Selection) -> SearchContentViewController) {
        self.selection = selected
        self.executor = executor
        super.init(rootViewController: UIViewController())
        let searchController = SearchViewController(executor: executor, initialSearchTerm: initialSearchTerm) { [weak self] parent, _, object in
            guard let self else { return }
            guard !object.isEmpty else {
                self.showError(CelestiaString("Object not found", comment: ""))
                return
            }
            let viewController = self.selection(object)
            parent.installContentViewController(viewController)
        }
        #if !targetEnvironment(macCatalyst)
        searchController.searchActivationHandler = { [weak self] in
            self?.searchActivationHandler?()
        }
        searchController.cancelHandler = { [weak self] in
            self?.closeSheet()
        }
        searchController.sheetCloseButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeSheet))
        #endif
        setViewControllers([searchController], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if !targetEnvironment(macCatalyst)
    @objc private func closeSheet() {
        presentingViewController?.dismiss(animated: true)
    }
    #endif
}

extension InfoViewController: SearchContentViewController {
    public var contentScrollView: UIScrollView? { return collectionView }
}
