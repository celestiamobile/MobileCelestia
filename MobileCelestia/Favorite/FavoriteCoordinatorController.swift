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
import CelestiaUI
import UIKit

enum FavoriteRoot {
    case main
}

#if targetEnvironment(macCatalyst)
@available(macCatalyst 16.0, *)
class FavoriteNavigationController: UINavigationController, UINavigationBarDelegate {
    func navigationBarNSToolbarSection(_ navigationBar: UINavigationBar) -> UINavigationBar.NSToolbarSection {
        return .content
    }
}
#endif

class FavoriteCoordinatorController: UIViewController {
    #if targetEnvironment(macCatalyst)
    private lazy var controller = UISplitViewController()
    #endif
    private var navigation: UINavigationController!

    @Injected(\.appCore) private var core

    private lazy var main = FavoriteViewController(currentSelection: nil, selected: { [unowned self] (item) in
        switch item {
        case .bookmark:
            self.replace(self.bookmarkRoot)
        case .script:
            self.replace(AnyFavoriteItemList(title: CelestiaString("Scripts", comment: ""), items: readScripts()))
        case .destination:
            self.replace(AnyFavoriteItemList(title: CelestiaString("Destinations", comment: ""), items: core.destinations))
        }
    })

    private lazy var bookmarkRoot: BookmarkNode = {
        let node = BookmarkNode(name: CelestiaString("Bookmarks", comment: ""),
                                url: "",
                                isFolder: true, children: readBookmarks())
        return node
    }()

    private let root: FavoriteRoot
    private let selected: (Any) -> Void
    private let share: (Any, UIViewController) -> Void

    init(root: FavoriteRoot, selected: @escaping (Any) -> Void, share: @escaping (Any, UIViewController) -> Void) {
        self.root = root
        self.selected = selected
        self.share = share
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        storeBookmarks(bookmarkRoot.children)
    }
}

private extension FavoriteCoordinatorController {
    func setup() {
        #if targetEnvironment(macCatalyst)
        controller.primaryBackgroundStyle = .sidebar
        controller.preferredDisplayMode = .oneBesideSecondary
        controller.preferredPrimaryColumnWidthFraction = 0.3
        let contentVc: UIViewController
        let emptyVc = UIViewController()
        emptyVc.view.backgroundColor = .systemBackground
        contentVc = emptyVc
        controller.viewControllers = [main, contentVc]
        install(controller)
        #else
        navigation = UINavigationController(rootViewController: main)
        install(navigation)
        #endif
    }

    func replace<T: FavoriteItemList>(_ itemList: T) {
        #if targetEnvironment(macCatalyst)
        if #available(macCatalyst 16.0, *) {
            navigation = FavoriteNavigationController(rootViewController: generateVC(itemList))
        } else {
            navigation = UINavigationController(rootViewController: generateVC(itemList))
        }
        controller.viewControllers = [controller.viewControllers[0], navigation]
        if #available(macCatalyst 16.0, *) {
            let scene = view.window?.windowScene
            scene?.titlebar?.titleVisibility = .visible
        }
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
            return self.core.currentBookmark as? T.Item
        }, share: { [weak self] object, viewController in
            self?.share(object, viewController)
        })
    }
}
