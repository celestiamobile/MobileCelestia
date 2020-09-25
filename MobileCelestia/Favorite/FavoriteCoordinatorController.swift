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

class FavoriteCoordinatorController: UIViewController {

    private var main: FavoriteViewController!
    private var navigation: UINavigationController!

    private lazy var bookmarkRoot: BookmarkNode = {
        let node = BookmarkNode(name: CelestiaString("Bookmarks", comment: ""),
                                url: "",
                                isFolder: true, children: readBookmarks())
        return node
    }()

    private let selected: (URL) -> Void

    init(selected: @escaping (URL) -> Void) {
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
        main = FavoriteViewController(selected: { [unowned self] (item) in
            switch item {
            case .bookmark:
                self.show(self.bookmarkRoot)
            case .script:
                self.show(readScripts())
            }
        })
        navigation = UINavigationController(rootViewController: main)

        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.barTintColor = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }

    func show<T: FavoriteItemList>(_ itemList: T) {
        self.navigation.pushViewController(FavoriteItemViewController(item: itemList, selection: { [unowned self] (item) in
            if item.isLeaf {
                self.selected(item.associatedURL!)
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
        }), animated: true)
    }
}
