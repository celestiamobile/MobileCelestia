//
// BrowserContainerViewController.swift
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

class BrowserContainerViewController: UIViewController {
    #if targetEnvironment(macCatalyst)
    private lazy var controller = UISplitViewController()
    #else
    private lazy var controller = UITabBarController()
    #endif

    private let selected: (CelestiaSelection) -> Void

    init(selected: @escaping (CelestiaSelection) -> Void) {
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

}

private extension BrowserContainerViewController {
    func setup() {
        install(controller)
        let handler = { [unowned self] (selection: CelestiaSelection) in
            self.dismiss(animated: true, completion: nil)
            self.selected(selection)
        }

        #if targetEnvironment(macCatalyst)
        controller.primaryBackgroundStyle = .sidebar
        controller.preferredDisplayMode = .oneBesideSecondary
        controller.preferredPrimaryColumnWidthFraction = 0.3
        let sidebarController = BrowserSidebarController(browserRoots: [solBrowserRoot, starBrowserRoot, dsoBrowserRoot]) { [unowned self] item in
            let newVc = BrowserCoordinatorController(item: item, image: UIImage(), selection: handler)
            controller.viewControllers = [self.controller.viewControllers[0], newVc]
        }
        let emptyVc = UIViewController()
        emptyVc.view.backgroundColor = .darkBackground
        controller.viewControllers = [sidebarController, emptyVc]
        #else
        controller.setViewControllers([
            BrowserCoordinatorController(item: solBrowserRoot, image: #imageLiteral(resourceName: "browser_tab_sso"), selection: handler),
            BrowserCoordinatorController(item: starBrowserRoot, image: #imageLiteral(resourceName: "browser_tab_star"), selection: handler),
            BrowserCoordinatorController(item: dsoBrowserRoot, image: #imageLiteral(resourceName: "browser_tab_dso"), selection: handler),
        ], animated: false)

        controller.tabBar.barStyle = .black
        controller.tabBar.barTintColor = .black
        #endif
    }
}

#if targetEnvironment(macCatalyst)
class BrowserSidebarController: UIViewController {
    private lazy var layout: UICollectionViewLayout = {
        let configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        return layout
    }()

    enum Section {
        case single
    }

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, CelestiaBrowserItem> = {
        let registration = UICollectionView.CellRegistration { (cell: UICollectionViewListCell, indexPath, item: CelestiaBrowserItem) in
            var config = cell.defaultContentConfiguration()
            config.text = item.alternativeName ?? item.name
            cell.contentConfiguration = config
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, CelestiaBrowserItem>(collectionView: collectionView) { (view, indexPath, item) -> UICollectionViewCell? in
            return view.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: item)
        }
        return dataSource
    }()

    private let browserRoots: [CelestiaBrowserItem]
    private let handler: (CelestiaBrowserItem) -> Void

    override func loadView() {
        let container = UIView()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: container.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        view = container
    }

    init(browserRoots: [CelestiaBrowserItem], handler: @escaping (CelestiaBrowserItem) -> Void) {
        self.browserRoots = browserRoots
        self.handler = handler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var snapshot = NSDiffableDataSourceSnapshot<Section, CelestiaBrowserItem>()
        snapshot.appendSections([.single])
        snapshot.appendItems(browserRoots, toSection: .single)
        dataSource.apply(snapshot)
        collectionView.dataSource = dataSource
        collectionView.delegate = self
    }
}

extension BrowserSidebarController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        handler(item)
    }
}

#endif
