//
// FavoriteCoordinatorController.swift
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

public enum FavoriteRoot {
    case main
    case bookmarks
}

public class FavoriteCoordinatorController: UIViewController {
    #if targetEnvironment(macCatalyst)
    private lazy var controller = ToolbarSplitContainerController(sidebarViewController: main)
    #endif
    private var navigation: UINavigationController!

    private let executor: AsyncProviderExecutor
    private let extraScriptDirectoryPathProvider: (() -> String?)?

    private lazy var main: FavoriteViewController = {
        let type: FavoriteItemType?
        switch root {
        case .main:
            type = nil
        case .bookmarks:
            type = .bookmark
        }
        return FavoriteViewController(currentSelection: type, selected: { [weak self] (item) in
            guard let self else { return }
            switch item {
            case .bookmark:
                self.replace(self.bookmarkRoot)
            case .script:
                self.replace(AnyFavoriteItemList(title: CelestiaString("Scripts", comment: ""), items: scripts))
            case .destination:
                Task {
                    let destinations = await self.executor.get { $0.destinations }
                    self.replace(AnyFavoriteItemList(title: CelestiaString("Destinations", comment: ""), items: destinations))
                }
            }
        })
    }()

    private lazy var scripts: [Script] = {
        var scripts = Script.scripts(inDirectory: "scripts", deepScan: true)
        if let extraScriptsPath = self.extraScriptDirectoryPathProvider?() {
            scripts += Script.scripts(inDirectory: extraScriptsPath, deepScan: true)
        }
        return scripts
    }()

    private lazy var bookmarkRoot: BookmarkNode = {
        let node = BookmarkNode(
            name: CelestiaString("Bookmarks", comment: ""),
            url: "",
            isFolder: true,
            children: readBookmarks()
        )
        return node
    }()

    private let root: FavoriteRoot
    private let selected: (Any) -> Void
    private let share: (Any, UIViewController) -> Void
    private let textInputHandler: (_ viewController: UIViewController, _ title: String, _ text: String) async -> String?

    public init(
        executor: AsyncProviderExecutor,
        root: FavoriteRoot,
        extraScriptDirectoryPathProvider: (() -> String?)? = nil,
        selected: @escaping (Any) -> Void,
        share: @escaping (Any, UIViewController) -> Void,
        textInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ text: String) async -> String?
    ) {
        self.executor = executor
        self.root = root
        self.extraScriptDirectoryPathProvider = extraScriptDirectoryPathProvider
        self.selected = selected
        self.share = share
        self.textInputHandler = textInputHandler
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        storeBookmarks(bookmarkRoot.children)
        UIMenuSystem.main.setNeedsRebuild()
    }
}

private extension FavoriteCoordinatorController {
    func setUp() {
        #if targetEnvironment(macCatalyst)
        install(controller)
        #else
        navigation = UINavigationController(rootViewController: main)
        install(navigation)
        #endif
    }

    func replace<T: FavoriteItemList>(_ itemList: T) {
        #if targetEnvironment(macCatalyst)
        let vc = generateVC(itemList)
        navigation = controller.setSecondaryViewController(vc)
        #else
        show(itemList)
        #endif
    }

    func show<T: FavoriteItemList>(_ itemList: T) {
        navigation.pushViewController(generateVC(itemList), animated: true)
    }

    func generateVC<T: FavoriteItemList>(_ itemList: T) -> UIViewController {
        FavoriteItemViewController(item: itemList, selection: { [unowned self] (item) in
            if item.isLeaf {
                if let destination = item.associatedObject as? Destination {
                    let vc = DestinationDetailViewController(destination: destination) {
                        self.selected(destination)
                    }
                    self.navigation.pushViewController(vc, animated: true)
                } else {
                    self.selected(item.associatedObject!)
                }
            } else if let itemList = item.itemList {
                self.show(itemList)
            } else {
                self.showError(CelestiaString("Object not found", comment: ""))
            }
        }, add: { [weak self] in
            guard itemList is BookmarkNode, let self else {
                fatalError()
            }
            return await self.executor.get { $0.currentBookmark } as? T.Item
        }, share: { [weak self] object, viewController in
            self?.share(object, viewController)
        }, textInputHandler: textInputHandler)
    }
}

#if targetEnvironment(macCatalyst)
extension FavoriteCoordinatorController: ToolbarContainerViewController {
    public var nsToolbar: NSToolbar? {
        get { controller.nsToolbar }
        set { controller.nsToolbar = newValue }
    }

    public func updateToolbar(for viewController: UIViewController) {
        controller.updateToolbar(for: viewController)
    }
}
#endif
