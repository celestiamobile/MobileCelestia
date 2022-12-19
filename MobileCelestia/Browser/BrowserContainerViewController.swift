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

    private let selected: (Selection) -> UIViewController

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    init(selected: @escaping (Selection) -> UIViewController) {
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

        setUp()

        let core = AppCore.shared
        activityIndicator.startAnimating()
        core.run { [weak self] core in
            createStaticBrowserItems()
            createDynamicBrowserItems()
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                self.rootItemsLoaded()
            }
        }
    }
}

private extension BrowserContainerViewController {
    func setUp() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func rootItemsLoaded() {
        activityIndicator.isHidden = true

        install(controller)
        let handler = { [unowned self] (selection: Selection) -> UIViewController in
            return self.selected(selection)
        }

        #if targetEnvironment(macCatalyst)
        let browserRoots = [solBrowserRoot, starBrowserRoot, dsoBrowserRoot].compactMap { $0 }
        controller.primaryBackgroundStyle = .sidebar
        controller.preferredDisplayMode = .oneBesideSecondary
        controller.preferredPrimaryColumnWidthFraction = 0.3
        let sidebarController = BrowserSidebarController(browserRoots: browserRoots) { [weak self] item in
            guard let self else { return }
            let newVc = BrowserCoordinatorController(item: item, image: UIImage(), selection: handler)
            self.controller.viewControllers = [self.controller.viewControllers[0], newVc]

            if #available(macCatalyst 16.0, *) {
                let scene = self.view.window?.windowScene
                scene?.titlebar?.titleVisibility = .visible
            }
        }
        let emptyVc = UIViewController()
        emptyVc.view.backgroundColor = .darkBackground
        controller.viewControllers = [sidebarController, emptyVc]
        #else
        var allControllers = [BrowserCoordinatorController]()
        if let solRoot = solBrowserRoot {
            allControllers.append(BrowserCoordinatorController(item: solRoot, image: #imageLiteral(resourceName: "browser_tab_sso"), selection: handler))
        }
        if let starRoot = starBrowserRoot {
            allControllers.append(BrowserCoordinatorController(item: starRoot, image: #imageLiteral(resourceName: "browser_tab_star"), selection: handler))
        }
        if let dsoRoot = dsoBrowserRoot {
            allControllers.append(BrowserCoordinatorController(item: dsoRoot, image: #imageLiteral(resourceName: "browser_tab_dso"), selection: handler))
        }
        controller.setViewControllers(allControllers, animated: false)

        if #available(iOS 13.0, *) {
        } else {
            controller.tabBar.barStyle = .black
            controller.tabBar.barTintColor = .darkBackground
        }
        #endif
    }
}

#if targetEnvironment(macCatalyst)
class BrowserSidebarController: BaseTableViewController {
    enum Section {
        case single
    }

    private lazy var dataSource: UITableViewDiffableDataSource<Section, BrowserItem> = {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        let dataSource = UITableViewDiffableDataSource<Section, BrowserItem>(tableView: tableView) { (view, indexPath, item) -> UITableViewCell? in
            let cell = view.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = item.alternativeName ?? item.name
            return cell
        }
        return dataSource
    }()

    private let browserRoots: [BrowserItem]
    private let handler: (BrowserItem) -> Void

    init(browserRoots: [BrowserItem], handler: @escaping (BrowserItem) -> Void) {
        self.browserRoots = browserRoots
        self.handler = handler
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var snapshot = NSDiffableDataSourceSnapshot<Section, BrowserItem>()
        snapshot.appendSections([.single])
        snapshot.appendItems(browserRoots, toSection: .single)
        tableView.dataSource = dataSource
        tableView.rowHeight = UITableView.automaticDimension
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handler(browserRoots[indexPath.row])
    }
}
#endif
