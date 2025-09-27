// InstalledResourceViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

extension ResourceItem: AsyncListItem, @unchecked Sendable {
    var imageURL: (URL, String)? {
        if let image = self.image {
            return (image, id)
        }
        return nil
    }
}

class InstalledResourceViewController: AsyncListViewController<ResourceItem> {
    private let resourceManager: ResourceManager
    private let getAddonsHandler: () -> Void

    private lazy var emptyView: UIView = {
        let view = EmptyHintView()
        view.title = CelestiaString("Enhance Celestia with online add-ons", comment: "")
        view.actionText = CelestiaString("Get Add-ons", comment: "Open webpage for downloading add-ons")
        view.action = { [weak self] in
            guard let self else { return }
            self.getAddonsHandler()
        }
        return view
    }()

    override class var alwaysRefreshOnAppear: Bool { return true }

    init(resourceManager: ResourceManager, selection: @escaping (ResourceItem) -> Void, getAddonsHandler: @escaping () -> Void) {
        self.resourceManager = resourceManager
        self.getAddonsHandler = getAddonsHandler
        super.init(selection: selection)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = CelestiaString("Installed", comment: "Title for the list of installed add-ons")
        windowTitle = title
    }

    override func loadItems(pageStart: Int, pageSize: Int) async throws -> [ResourceItem] {
        let resourceManager = self.resourceManager
        return await Task.detached(priority: .background) {
            let items = resourceManager.installedResources()
            if pageStart >= items.count {
                return []
            } else {
                return Array(items[pageStart..<min(items.count, pageStart + pageSize)])
            }
        }.value
    }

    override func emptyHintView() -> UIView? {
        return emptyView
    }

    @available(iOS 17, visionOS 1, *)
    override func emptyViewConfiguration() -> UIContentUnavailableConfiguration? {
        var config = UIContentUnavailableConfiguration.empty()
        config.text = CelestiaString("Enhance Celestia with online add-ons", comment: "")
        #if !targetEnvironment(macCatalyst)
        let button = UIButton.Configuration.filled()
        config.button = button
        #endif
        config.button.title = CelestiaString("Get Add-ons", comment: "Open webpage for downloading add-ons")
        config.buttonProperties.primaryAction = UIAction { [weak self] _ in
            guard let self else { return }
            self.getAddonsHandler()
        }
        return config
    }
}
