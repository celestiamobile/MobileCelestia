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

    private let selected: (CelestiaSelection) -> UIViewController

    init(selected: @escaping (CelestiaSelection) -> UIViewController) {
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

}

private extension BrowserContainerViewController {
    func setup() {
        install(controller)
        let handler = { [unowned self] (selection: CelestiaSelection) -> UIViewController in
            return self.selected(selection)
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
        emptyVc.view.backgroundColor = .darkBackgroundElevated
        controller.viewControllers = [sidebarController, emptyVc]
        #else
        controller.setViewControllers([
            BrowserCoordinatorController(item: solBrowserRoot, image: #imageLiteral(resourceName: "browser_tab_sso"), selection: handler),
            BrowserCoordinatorController(item: starBrowserRoot, image: #imageLiteral(resourceName: "browser_tab_star"), selection: handler),
            BrowserCoordinatorController(item: dsoBrowserRoot, image: #imageLiteral(resourceName: "browser_tab_dso"), selection: handler),
        ], animated: false)

        if #available(iOS 13.0, *) {
        } else {
            controller.tabBar.barStyle = .black
            controller.tabBar.barTintColor = .darkBackgroundElevated
        }
        #endif
    }
}

#if targetEnvironment(macCatalyst)
class BrowserSidebarController: BaseTableViewController {
    enum Section {
        case single
    }

    private lazy var dataSource: UITableViewDiffableDataSource<Section, CelestiaBrowserItem> = {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        let dataSource = UITableViewDiffableDataSource<Section, CelestiaBrowserItem>(tableView: tableView) { (view, indexPath, item) -> UITableViewCell? in
            let cell = view.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = item.alternativeName ?? item.name
            return cell
        }
        return dataSource
    }()

    private let browserRoots: [CelestiaBrowserItem]
    private let handler: (CelestiaBrowserItem) -> Void

    init(browserRoots: [CelestiaBrowserItem], handler: @escaping (CelestiaBrowserItem) -> Void) {
        self.browserRoots = browserRoots
        self.handler = handler
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var snapshot = NSDiffableDataSourceSnapshot<Section, CelestiaBrowserItem>()
        snapshot.appendSections([.single])
        snapshot.appendItems(browserRoots, toSection: .single)
        tableView.dataSource = dataSource
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handler(browserRoots[indexPath.row])
    }
}
#endif
