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
    #if targetEnvironment(macCatalyst)
    private lazy var controller = UISplitViewController()
    #endif
    private var navigation: UINavigationController!

    private lazy var main = FavoriteViewController(currentSelection: root == .destinations ? .destination : nil, selected: { [unowned self] (item) in
        switch item {
        case .bookmark:
            self.replace(self.bookmarkRoot)
        case .script:
            self.replace(AnyFavoriteItemList(title: CelestiaString("Scripts", comment: ""), items: readScripts()))
        case .destination:
            self.replace(AnyFavoriteItemList(title: CelestiaString("Destinations", comment: ""), items: CelestiaAppCore.shared.destinations))
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
        view.backgroundColor = .darkBackgroundElevated
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
        let anotherVc = root == .destinations ? generateVC(AnyFavoriteItemList(title: CelestiaString("Destinations", comment: ""), items: CelestiaAppCore.shared.destinations)) : nil
        #if targetEnvironment(macCatalyst)
        controller.primaryBackgroundStyle = .sidebar
        controller.preferredDisplayMode = .oneBesideSecondary
        controller.preferredPrimaryColumnWidthFraction = 0.3
        let contentVc: UIViewController
        if let another = anotherVc {
            navigation = UINavigationController(rootViewController: another)
            if #available(iOS 13.0, *) {
            } else {
                navigation.navigationBar.barStyle = .black
                navigation.navigationBar.barTintColor = .darkBackgroundElevated
                navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
            }
            contentVc = navigation
        } else {
            let emptyVc = UIViewController()
            emptyVc.view.backgroundColor = .darkBackgroundElevated
            contentVc = emptyVc
        }
        controller.viewControllers = [main, contentVc]
        install(controller)
        #else
        navigation = UINavigationController(rootViewController: anotherVc ?? main)
        install(navigation)
        if #available(iOS 13.0, *) {
        } else {
            navigation.navigationBar.barStyle = .black
            navigation.navigationBar.barTintColor = .darkBackgroundElevated
            navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
        }
        #endif
    }

    func replace<T: FavoriteItemList>(_ itemList: T) {
        #if targetEnvironment(macCatalyst)
        navigation = UINavigationController(rootViewController: generateVC(itemList))
        if #available(iOS 13.0, *) {
        } else {
            navigation.navigationBar.barStyle = .black
            navigation.navigationBar.barTintColor = .darkBackgroundElevated
            navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
        }
        controller.viewControllers = [controller.viewControllers[0], navigation]
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
