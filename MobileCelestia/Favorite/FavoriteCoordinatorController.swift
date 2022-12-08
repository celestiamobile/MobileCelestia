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

import UIKit

import CelestiaCore

enum FavoriteRoot {
    case main
    case destinations
}

class FavoriteCoordinatorController: UINavigationController {
    private lazy var main = FavoriteViewController(currentSelection: root == .destinations ? .destination : nil, selected: { [unowned self] (item) in
        switch item {
        case .bookmark:
            self.replace(self.bookmarkRoot)
        case .script:
            self.replace(AnyFavoriteItemList(title: CelestiaString("Scripts", comment: ""), items: readScripts()))
        case .destination:
            self.replace(AnyFavoriteItemList(title: CelestiaString("Destinations", comment: ""), items: AppCore.shared.destinations))
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
        super.init(rootViewController: UIViewController())
        let vc = root == .destinations ? generateVC(AnyFavoriteItemList(title: CelestiaString("Destinations", comment: ""), items: AppCore.shared.destinations)) : main
        setViewControllers([vc], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        storeBookmarks(bookmarkRoot.children)
    }
}

private extension FavoriteCoordinatorController {
    func replace<T: FavoriteItemList>(_ itemList: T) {
        show(itemList)
    }

    func show<T: FavoriteItemList>(_ itemList: T) {
        pushViewController(generateVC(itemList), animated: true)
    }

    func generateVC<T: FavoriteItemList>(_ itemList: T) -> UIViewController {
        FavoriteItemViewController(item: itemList, selection: { [unowned self] (item) in
            if item.isLeaf {
                if let destination = item.associatedObject as? Destination {
                    let vc = DestinationDetailViewController(destination: destination) {
                        self.selected(destination)
                    }
                    self.pushViewController(vc, animated: true)
                } else {
                    self.selected(item.associatedObject!)
                }
            } else if let itemList = item.itemList {
                self.show(itemList)
            } else {
                self.showError(CelestiaString("Object not found", comment: ""))
            }
        }, add: {
            guard itemList is BookmarkNode else {
                fatalError()
            }
            return AppCore.shared.currentBookmark as? T.Item
        }, share: { [weak self] object, viewController in
            self?.share(object, viewController)
        })
    }
}
