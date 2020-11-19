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

class FavoriteCoordinatorController: UIViewController {
    private var navigation: UINavigationController!

    private lazy var bookmarkRoot: BookmarkNode = {
        let node = BookmarkNode(name: CelestiaString("Bookmarks", comment: ""),
                                url: "",
                                isFolder: true, children: readBookmarks())
        return node
    }()

    private let root: FavoriteRoot
    private let selected: (Any) -> Void

    init(root: FavoriteRoot, selected: @escaping (Any) -> Void) {
        self.root = root
        self.selected = selected
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground
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
        let rootVC: UIViewController
        switch root {
        case .main:
            rootVC = FavoriteViewController(selected: { [unowned self] (item) in
                switch item {
                case .bookmark:
                    self.show(self.bookmarkRoot)
                case .script:
                    self.show(AnyFavoriteItemList(title: CelestiaString("Scripts", comment: ""), items: readScripts()))
                case .destination:
                    self.show(AnyFavoriteItemList(title: CelestiaString("Destinations", comment: ""), items: CelestiaAppCore.shared.destinations))
                }
            })
        case .destinations:
            rootVC = generateVC(AnyFavoriteItemList(title: CelestiaString("Destinations", comment: ""), items: CelestiaAppCore.shared.destinations))
        }
        navigation = UINavigationController(rootViewController: rootVC)

        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.barTintColor = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }

    func show<T: FavoriteItemList>(_ itemList: T) {
        self.navigation.pushViewController(generateVC(itemList), animated: true)
    }

    func generateVC<T: FavoriteItemList>(_ itemList: T) -> UIViewController {
        FavoriteItemViewController(item: itemList, selection: { [unowned self] (item) in
            if item.isLeaf {
                if let destination = item.associatedObject as? CelestiaDestination {
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
        }, add: {
            guard itemList is BookmarkNode else {
                fatalError()
            }
            return CelestiaAppCore.shared.currentBookmark as? T.Item
        })
    }
}
