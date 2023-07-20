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

import CelestiaCore
import UIKit

public class BrowserContainerViewController: UIViewController {
    #if targetEnvironment(macCatalyst)
    private lazy var controller: UISplitViewController = {
        if #available(macCatalyst 16, *) {
            return UISplitViewController(style: .doubleColumn)
        } else {
            return UISplitViewController()
        }
    }()
    #else
    private lazy var controller = UITabBarController()
    #endif

    private var executor: AsyncProviderExecutor

    private static var solBrowserRoot: BrowserItem?
    private static var dsoBrowserRoot: BrowserItem?
    private static var brightestStars: BrowserItem?
    private static var starsWithPlanets: BrowserItem?
    private var brighterStars: BrowserItem?
    private var nearestStars: BrowserItem?

    private let selected: (Selection) -> UIViewController

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    public init(selected: @escaping (Selection) -> UIViewController, executor: AsyncProviderExecutor) {
        self.selected = selected
        self.executor = executor
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

        activityIndicator.startAnimating()
        Task {
            let shouldGenerateStaticItems = Self.solBrowserRoot == nil || Self.dsoBrowserRoot == nil || Self.brightestStars == nil || Self.starsWithPlanets == nil

            let items = await executor.get({ core in self.createAllItems(shouldGenerateStaticItems: shouldGenerateStaticItems, core: core) })
            if shouldGenerateStaticItems {
                if let solBrowserRoot = items.solBrowserRoot {
                    Self.solBrowserRoot = solBrowserRoot
                }
                if let dsoBrowserRoot = items.dsoBrowserRoot {
                    Self.dsoBrowserRoot = dsoBrowserRoot
                }
                if let brightestStars = items.brightestStars {
                    Self.brightestStars = brightestStars
                }
                if let starsWithPlanets = items.starsWithPlanets {
                    Self.starsWithPlanets = starsWithPlanets
                }
            }
            self.nearestStars = items.nearestStars
            self.brighterStars = items.brighterStars
            self.activityIndicator.stopAnimating()
            self.rootItemsLoaded()
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

        var starChildren = [String: BrowserItem]()
        for item in [nearestStars, brighterStars, Self.brightestStars, Self.starsWithPlanets] {
            if let item {
                starChildren[item.name] = item
            }
        }
        let starBrowserRoot = BrowserItem(name: CelestiaString("Stars", comment: ""), children: starChildren)

        #if targetEnvironment(macCatalyst)
        let rawBrowserRoots: [(item: BrowserItem?, image: UIImage)] = [
            (Self.solBrowserRoot, #imageLiteral(resourceName: "browser_tab_sso")),
            (starBrowserRoot, #imageLiteral(resourceName: "browser_tab_star")),
            (Self.dsoBrowserRoot, #imageLiteral(resourceName: "browser_tab_dso"))
        ]
        let browserRoot = rawBrowserRoots.compactMap { item in
            if let browserItem = item.item {
                return (browserItem, item.image)
            } else {
                return nil
            }
        }
        controller.primaryBackgroundStyle = .sidebar
        controller.preferredDisplayMode = .oneBesideSecondary
        controller.preferredPrimaryColumnWidthFraction = 0.3
        let sidebarController = BrowserSidebarController(browserRoots: browserRoot) { [weak self] item in
            guard let self else { return }
            let newVc = BrowserCoordinatorController(item: item, image: UIImage(), selection: handler)
            if #available(macCatalyst 16, *) {
                self.controller.setViewController(newVc, for: .secondary)
                let scene = self.view.window?.windowScene
                scene?.titlebar?.titleVisibility = .visible
            } else {
                self.controller.viewControllers = [self.controller.viewControllers[0], newVc]
            }
        }
        let emptyVc = UIViewController()
        emptyVc.view.backgroundColor = .systemBackground
        if #available(macCatalyst 16.0, *) {
            controller.setViewController(SidebarNavigationController(rootViewController: sidebarController), for: .primary)
            controller.setViewController(ContentNavigationController(rootViewController: emptyVc), for: .secondary)
        } else {
            controller.viewControllers = [sidebarController, ContentNavigationController(rootViewController: emptyVc)]
        }
        #else
        var allControllers = [BrowserCoordinatorController]()
        if let solRoot = Self.solBrowserRoot {
            allControllers.append(BrowserCoordinatorController(item: solRoot, image: #imageLiteral(resourceName: "browser_tab_sso"), selection: handler))
        }
        allControllers.append(BrowserCoordinatorController(item: starBrowserRoot, image: #imageLiteral(resourceName: "browser_tab_star"), selection: handler))
        if let dsoRoot = Self.dsoBrowserRoot {
            allControllers.append(BrowserCoordinatorController(item: dsoRoot, image: #imageLiteral(resourceName: "browser_tab_dso"), selection: handler))
        }
        controller.setViewControllers(allControllers, animated: false)
        #endif
    }
}

#if targetEnvironment(macCatalyst)
class BrowserSidebarController: BaseTableViewController {
    enum Section {
        case single
    }

    private struct Item: Hashable, @unchecked Sendable {
        let item: BrowserItem
        let image: UIImage
    }

    private lazy var dataSource: UITableViewDiffableDataSource<Section, Item> = {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        let dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView) { (view, indexPath, item) -> UITableViewCell? in
            let cell = view.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = item.item.alternativeName ?? item.item.name
            cell.imageView?.image = item.image
            return cell
        }
        return dataSource
    }()

    private let browserRoots: [Item]
    private let handler: (BrowserItem) -> Void

    init(browserRoots: [(item: BrowserItem, image: UIImage)], handler: @escaping (BrowserItem) -> Void) {
        self.browserRoots = browserRoots.map { Item(item: $0.item, image: $0.image) }
        self.handler = handler
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.single])
        snapshot.appendItems(browserRoots, toSection: .single)
        tableView.dataSource = dataSource
        tableView.rowHeight = UITableView.automaticDimension
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handler(browserRoots[indexPath.row].item)
    }
}
#endif

private extension BrowserContainerViewController {
    nonisolated func createSolBrowserRoot(_ core: AppCore) -> BrowserItem? {
        let universe = core.simulation.universe
        if let sol = universe.find("Sol").star {
            return BrowserItem(name: universe.starCatalog.starName(sol), alternativeName: CelestiaString("Solar System", comment: ""), catEntry: sol, provider: universe)
        }
        return nil
    }

    nonisolated func createDSOBrowserRoot(_ core: AppCore) -> BrowserItem? {
        let universe = core.simulation.universe

        let typeMap = [
            "SB" : CelestiaString("Galaxies (Barred Spiral)", comment: ""),
            "S" : CelestiaString("Galaxies (Spiral)", comment: ""),
            "E" : CelestiaString("Galaxies (Elliptical)", comment: ""),
            "Irr" : CelestiaString("Galaxies (Irregular)", comment: ""),
            "Neb" : CelestiaString("Nebulae", comment: ""),
            "Glob" : CelestiaString("Globulars", comment: ""),
            "Open cluster" : CelestiaString("Open Clusters", comment: ""),
            "Unknown" : CelestiaString("Unknown", comment: ""),
        ]

        func updateAccumulation(result: inout [String : BrowserItem], item: (key: String, value: [String : BrowserItem])) {
            let fullName = typeMap[item.key]!
            result[fullName] = BrowserItem(name: fullName, children: item.value)
        }

        let prefixes = ["SB", "S", "E", "Irr", "Neb", "Glob", "Open cluster"]

        var tempDict = prefixes.reduce(into: [String : [String : BrowserItem]]()) { $0[$1] = [String : BrowserItem]() }

        let catalog = universe.dsoCatalog
        catalog.forEach({ (dso) in
            let matchingType = prefixes.first(where: {dso.type.hasPrefix($0)}) ?? "Unknown"
            let name = catalog.dsoName(dso)
            if tempDict[matchingType] != nil {
                tempDict[matchingType]![name] = BrowserItem(name: name, catEntry: dso, provider: universe)
            }
        })

        let results = tempDict.reduce(into: [String : BrowserItem](), updateAccumulation)
        return BrowserItem(name: CelestiaString("Deep Sky Objects", comment: ""), alternativeName: CelestiaString("DSOs", comment: ""), children: results)
    }

    nonisolated func createStarBrowserRootItem(kind: StarBrowserKind, title: String, ordered: Bool, core: AppCore) -> BrowserItem {
        let simulation = core.simulation
        let universe = simulation.universe

        func updateAccumulation(result: inout [String : BrowserItem], star: Star) {
            let name = universe.starCatalog.starName(star)
            result[name] = BrowserItem(name: name, catEntry: star, provider: universe)
        }

        func updateAccumulationOrdered(result: inout [BrowserItemKeyValuePair], star: Star) {
            let name = universe.starCatalog.starName(star)
            result.append(BrowserItemKeyValuePair(name: name, browserItem: BrowserItem(name: name, catEntry: star, provider: universe)))
        }

        if ordered {
            let items = StarBrowser(kind: kind, simulation: simulation).stars().reduce(into: [BrowserItemKeyValuePair](), updateAccumulationOrdered)
            return BrowserItem(name: title, orderedChildren: items)
        } else {
            let items = StarBrowser(kind: kind, simulation: simulation).stars().reduce(into: [String : BrowserItem](), updateAccumulation)
            return BrowserItem(name: title, children: items)
        }
    }

    nonisolated func createNearestStars(_ core: AppCore) -> BrowserItem {
        return createStarBrowserRootItem(kind: .nearest, title: CelestiaString("Nearest Stars", comment: ""), ordered: true, core: core)
    }

    nonisolated func createBrightestStars(_ core: AppCore) -> BrowserItem {
        return createStarBrowserRootItem(kind: .brighter, title: CelestiaString("Brightest Stars", comment: ""), ordered: true, core: core)
    }

    nonisolated func createAbsoluteBrightestStars(_ core: AppCore) -> BrowserItem {
        return createStarBrowserRootItem(kind: .brightest, title: CelestiaString("Brightest Stars (Absolute Magnitude)", comment: ""), ordered: true, core: core)
    }

    nonisolated func createStarsWithPlanets(_ core: AppCore) -> BrowserItem {
        return createStarBrowserRootItem(kind: .starsWithPlants, title: CelestiaString("Stars with Planets", comment: ""), ordered: false, core: core)
    }

    nonisolated func createAllItems(shouldGenerateStaticItems: Bool, core: AppCore) -> (solBrowserRoot: BrowserItem?, dsoBrowserRoot: BrowserItem?, brightestStars: BrowserItem?, starsWithPlanets: BrowserItem?, brighterStars: BrowserItem, nearestStars: BrowserItem) {
        let brighter = createBrightestStars(core)
        let nearest = createNearestStars(core)
        if !shouldGenerateStaticItems {
            return (nil, nil, nil, nil, brighter, nearest)
        }
        return (createSolBrowserRoot(core), createDSOBrowserRoot(core), createAbsoluteBrightestStars(core), createStarsWithPlanets(core), brighter, nearest)
    }
}
