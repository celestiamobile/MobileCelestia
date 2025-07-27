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

extension BrowserItem: @unchecked @retroactive Sendable {}

public class BrowserContainerViewController: UIViewController {
    #if targetEnvironment(macCatalyst)
    private lazy var controller = ToolbarSplitContainerController()
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

    private let assetProvider: AssetProvider
    private let selected: (Selection) -> UIViewController
    private let showAddonCategory: (CategoryInfo) -> Void

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    public init(assetProvider: AssetProvider, selected: @escaping (Selection) -> UIViewController, showAddonCategory: @escaping (CategoryInfo) -> Void, executor: AsyncProviderExecutor) {
        self.assetProvider = assetProvider
        self.selected = selected
        self.showAddonCategory = showAddonCategory
        self.executor = executor
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()
        #if !os(visionOS)
        view.backgroundColor = .systemBackground
        #endif
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
        windowTitle = CelestiaString("Star Browser", comment: "")
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
        observeWindowTitle(for: controller)
        let handler = { [unowned self] (selection: Selection) -> UIViewController in
            return self.selected(selection)
        }

        var starChildren = [String: BrowserItem]()
        for item in [nearestStars, brighterStars, Self.brightestStars, Self.starsWithPlanets] {
            if let item {
                starChildren[item.name] = item
            }
        }
        let starBrowserRoot = BrowserPredefinedItem(name: CelestiaString("Stars", comment: "Tab for stars in Star Browser"), children: starChildren)
        starBrowserRoot.categoryInfo = CategoryInfo(category: "5E023C91-86F8-EC5C-B53C-E3780163514F", isLeaf: true)

        #if targetEnvironment(macCatalyst)
        let rawBrowserRoots: [(item: BrowserItem?, image: UIImage)] = [
            (Self.solBrowserRoot, assetProvider.image(for: .browserTabSso)),
            (starBrowserRoot, assetProvider.image(for: .browserTabStar)),
            (Self.dsoBrowserRoot, assetProvider.image(for: .browserTabDso))
        ]
        let browserRoot = rawBrowserRoots.compactMap { item in
            if let browserItem = item.item {
                return (browserItem, item.image)
            } else {
                return nil
            }
        }

        let sidebarController = BrowserSidebarController(browserRoots: browserRoot) { [weak self] item in
            guard let self else { return }
            let newVC = self.createBrowserItemViewController(item)
            self.controller.setSecondaryAndCompactViewController(newVC)
        }
        sidebarController.windowTitle = CelestiaString("Star Browser", comment: "")
        controller.setSidebarViewController(sidebarController)
        let emptyViewController = UIViewController()
        emptyViewController.view.backgroundColor = .systemBackground
        controller.setSecondaryAndCompactViewController(emptyViewController, isPlaceholder: true)
        #else
        var allControllers = [BrowserCoordinatorController]()
        if let solRoot = Self.solBrowserRoot {
            allControllers.append(BrowserCoordinatorController(item: solRoot, image: assetProvider.image(for: .browserTabSso), selection: handler, showAddonCategory: showAddonCategory))
        }
        allControllers.append(BrowserCoordinatorController(item: starBrowserRoot, image: assetProvider.image(for: .browserTabStar), selection: handler, showAddonCategory: showAddonCategory))
        if let dsoRoot = Self.dsoBrowserRoot {
            allControllers.append(BrowserCoordinatorController(item: dsoRoot, image: assetProvider.image(for: .browserTabDso), selection: handler, showAddonCategory: showAddonCategory))
        }
        controller.setViewControllers(allControllers, animated: false)
        #endif
    }

    #if targetEnvironment(macCatalyst)
    private func createBrowserItemViewController(_ item: BrowserItem) -> BrowserCommonViewController {
        return BrowserCommonViewController(item: item, selection: { [weak self] selection, finish in
            guard let self else { return }
            if !finish {
                let vc = self.createBrowserItemViewController(selection)
                self.controller.pushSecondaryViewController(vc, animated: true)
                return
            }
            guard let transformed = Selection(item: selection) else {
                self.showError(CelestiaString("Object not found", comment: ""))
                return
            }
            self.controller.pushSecondaryViewController(self.selected(transformed), animated: true)
        }, showAddonCategory: showAddonCategory)
    }
    #endif
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
            var contentConfiguration = UIListContentConfiguration.sidebarCell()
            contentConfiguration.text = item.item.alternativeName ?? item.item.name
            contentConfiguration.image = item.image
            contentConfiguration.imageProperties.reservedLayoutSize = CGSize(width: UIListContentConfiguration.ImageProperties.standardDimension, height: UIListContentConfiguration.ImageProperties.standardDimension)
            cell.contentConfiguration = contentConfiguration
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

public struct CategoryInfo: Codable, Hashable {
    public let category: String
    public let isLeaf: Bool
}

final class BrowserPredefinedItem: BrowserItem, @unchecked Sendable {
    var categoryInfo: CategoryInfo? = nil
}

private extension BrowserContainerViewController {
    nonisolated func createSolBrowserRoot(_ core: AppCore) -> BrowserItem? {
        let simulation = core.simulation
        let universe = simulation.universe
        if let sol = simulation.findObject(from: "Sol").star {
            let item = BrowserPredefinedItem(name: universe.starCatalog.starName(sol), alternativeName: CelestiaString("Solar System", comment: "Tab for solar system in Star Browser"), catEntry: sol, provider: universe)
            item.categoryInfo = CategoryInfo(category: "B2E44BE0-9DF7-FAB9-92D4-F8D323D31250", isLeaf: false)
            return item
        }
        return nil
    }

    nonisolated func createDSOBrowserRoot(_ core: AppCore) -> BrowserItem? {
        let universe = core.simulation.universe
        let galaxyCategory = CategoryInfo(category: "56FF5D9F-44F1-CE1D-0615-5655E3C851EF", isLeaf: true)
        let nebulaCategory = CategoryInfo(category: "3F7546F9-D225-5194-A228-C63281B5C6FD", isLeaf: true)

        class SubItem {
            let name: String
            var items: [String: BrowserItem]

            init(name: String, items: [String: BrowserItem]) {
                self.name = name
                self.items = items
            }
        }

        let barredSpiralItems = SubItem(name: CelestiaString("Barred Spiral Galaxies", comment: ""), items: [:])
        let spiralItems = SubItem(name: CelestiaString("Spiral Galaxies", comment: ""), items: [:])
        let ellipticalItems = SubItem(name: CelestiaString("Elliptical Galaxies", comment: ""), items: [:])
        let lenticularItems = SubItem(name: CelestiaString("Lenticular Galaxies", comment: ""), items: [:])
        let irregularItems = SubItem(name: CelestiaString("Irregular Galaxies", comment: ""), items: [:])
        let galaxyItems = [
            "SBa": barredSpiralItems,
            "SBb": barredSpiralItems,
            "SBc": barredSpiralItems,
            "Sa": spiralItems,
            "Sb": spiralItems,
            "Sc": spiralItems,
            "S0": lenticularItems,
            "E0": ellipticalItems,
            "E1": ellipticalItems,
            "E2": ellipticalItems,
            "E3": ellipticalItems,
            "E4": ellipticalItems,
            "E5": ellipticalItems,
            "E6": ellipticalItems,
            "E7": ellipticalItems,
            "Irr": irregularItems,
        ]
        let emissionItems = SubItem(name: CelestiaString("Emission Nebulae", comment: ""), items: [:])
        let reflectionItems = SubItem(name: CelestiaString("Reflection Nebulae", comment: ""), items: [:])
        let darkItems = SubItem(name: CelestiaString("Dark Nebulae", comment: ""), items: [:])
        let planetaryItems = SubItem(name: CelestiaString("Planetary Nebulae", comment: ""), items: [:])
        let supernovaRemnantItems = SubItem(name: CelestiaString("Supernova Remnants", comment: ""), items: [:])
        let hiiRegionItems = SubItem(name: CelestiaString("H II Regions", comment: ""), items: [:])
        let protoplanetaryItems = SubItem(name: CelestiaString("Protoplanetary Nebulae", comment: ""), items: [:])
        let unknownItems = SubItem(name: CelestiaString("Unknown Nebulae", comment: ""), items: [:])
        let nebulaItems = [
            "Emission": emissionItems,
            "Reflection": reflectionItems,
            "Dark": darkItems,
            "Planetary": planetaryItems,
            "Supernova Remnant": supernovaRemnantItems,
            "HII_Region": hiiRegionItems,
            "Protoplanetary": protoplanetaryItems,
            " ": unknownItems,
        ]

        var globularItems = [String: BrowserItem]()
        var openClusterItems = [String: BrowserItem]()

        let catalog = universe.dsoCatalog
        for dso in catalog {
            let name = catalog.dsoName(dso)

            switch dso.objectType {
            case .galaxy:
                if let subItem = galaxyItems[dso.type] {
                    subItem.items[name] = BrowserItem(name: name, catEntry: dso, provider: universe)
                }
            case .globular:
                globularItems[name] = BrowserItem(name: name, catEntry: dso, provider: universe)
            case .nebula:
                if let subItem = nebulaItems[dso.type] {
                    subItem.items[name] = BrowserItem(name: name, catEntry: dso, provider: universe)
                }
            case .openCluster:
                openClusterItems[name] = BrowserItem(name: name, catEntry: dso, provider: universe)
            @unknown default:
                continue
            }
        }
        var results = [BrowserItemKeyValuePair]()
        var galaxyBrowserItems = [BrowserItemKeyValuePair]()
        for subItem in [barredSpiralItems, spiralItems, ellipticalItems, lenticularItems, irregularItems] {
            if subItem.items.isEmpty { continue }
            galaxyBrowserItems.append(BrowserItemKeyValuePair(name: subItem.name, browserItem: BrowserItem(name: subItem.name, children: subItem.items)))
        }

        let galaxy = BrowserPredefinedItem(name: CelestiaString("Galaxies", comment: ""), orderedChildren: galaxyBrowserItems)
        galaxy.categoryInfo = galaxyCategory
        results.append(BrowserItemKeyValuePair(name: CelestiaString("Galaxies", comment: ""), browserItem: galaxy))

        results.append(BrowserItemKeyValuePair(name: CelestiaString("Globulars", comment: ""), browserItem: BrowserItem(name: CelestiaString("Globulars", comment: ""), children: globularItems)))

        var nebulaBrowserItems: [BrowserItemKeyValuePair] = []
        for subItem in [emissionItems, reflectionItems, darkItems, planetaryItems, supernovaRemnantItems, hiiRegionItems, protoplanetaryItems, unknownItems] {
            if subItem.items.isEmpty { continue }
            nebulaBrowserItems.append(BrowserItemKeyValuePair(name: subItem.name, browserItem: BrowserItem(name: subItem.name, children: subItem.items)))
        }

        let nebula = BrowserPredefinedItem(name: CelestiaString("Nebulae", comment: ""), orderedChildren: nebulaBrowserItems)
        nebula.categoryInfo = nebulaCategory
        results.append(BrowserItemKeyValuePair(name: CelestiaString("Nebulae", comment: ""), browserItem: nebula))

        results.append(BrowserItemKeyValuePair(name: CelestiaString("Open Clusters", comment: ""), browserItem: BrowserItem(name: CelestiaString("Open Clusters", comment: ""), children: openClusterItems)))

        return BrowserItem(name: CelestiaString("Deep Sky Objects", comment: ""), alternativeName: CelestiaString("DSOs", comment: "Tab for deep sky objects in Star Browser"), orderedChildren: results)
    }

    nonisolated func createStarBrowserRootItem(kind: StarBrowserKind, title: String, ordered: Bool, core: AppCore, category: CategoryInfo?) -> BrowserItem {
        let simulation = core.simulation
        let universe = simulation.universe
        let observer = simulation.activeObserver

        func updateAccumulation(result: inout [String : BrowserItem], star: Star) {
            let name = universe.starCatalog.starName(star)
            result[name] = BrowserItem(name: name, catEntry: star, provider: universe)
        }

        func updateAccumulationOrdered(result: inout [BrowserItemKeyValuePair], star: Star) {
            let name = universe.starCatalog.starName(star)
            result.append(BrowserItemKeyValuePair(name: name, browserItem: BrowserItem(name: name, catEntry: star, provider: universe)))
        }

        let browserItem: BrowserPredefinedItem
        if ordered {
            let items = StarBrowser(kind: kind, observer: observer, universe: universe).stars().reduce(into: [BrowserItemKeyValuePair](), updateAccumulationOrdered)
            browserItem = BrowserPredefinedItem(name: title, orderedChildren: items)
        } else {
            let items = StarBrowser(kind: kind, observer: observer, universe: universe).stars().reduce(into: [String : BrowserItem](), updateAccumulation)
            browserItem = BrowserPredefinedItem(name: title, children: items)
        }
        if let category {
            browserItem.categoryInfo = category
        }
        return browserItem
    }

    nonisolated func createNearestStars(_ core: AppCore) -> BrowserItem {
        return createStarBrowserRootItem(kind: .nearest, title: CelestiaString("Nearest Stars", comment: ""), ordered: true, core: core, category: nil)
    }

    nonisolated func createBrightestStars(_ core: AppCore) -> BrowserItem {
        return createStarBrowserRootItem(kind: .brighter, title: CelestiaString("Brightest Stars", comment: ""), ordered: true, core: core, category: nil)
    }

    nonisolated func createAbsoluteBrightestStars(_ core: AppCore) -> BrowserItem {
        return createStarBrowserRootItem(kind: .brightest, title: CelestiaString("Brightest Stars (Absolute Magnitude)", comment: ""), ordered: true, core: core, category: nil)
    }

    nonisolated func createStarsWithPlanets(_ core: AppCore) -> BrowserItem {
        return createStarBrowserRootItem(kind: .starsWithPlants, title: CelestiaString("Stars with Planets", comment: ""), ordered: true, core: core, category: CategoryInfo(category: "1B0E1953-C21C-D628-7FA6-33A3ABBD1B40", isLeaf: false))
    }

    nonisolated func createAllItems(shouldGenerateStaticItems: Bool, core: AppCore) -> (solBrowserRoot: BrowserItem?, dsoBrowserRoot: BrowserItem?, brightestStars: BrowserItem?, starsWithPlanets: BrowserItem?, brighterStars: BrowserItem, nearestStars: BrowserItem) {
        let brighter = createBrightestStars(core)
        let nearest = createNearestStars(core)
        let hasPlanets = createStarsWithPlanets(core)
        if !shouldGenerateStaticItems {
            return (nil, nil, nil, hasPlanets, brighter, nearest)
        }
        return (createSolBrowserRoot(core), createDSOBrowserRoot(core), createAbsoluteBrightestStars(core), hasPlanets, brighter, nearest)
    }
}

#if targetEnvironment(macCatalyst)
extension BrowserContainerViewController: ToolbarContainerViewController {
    public var nsToolbar: NSToolbar? {
        get { controller.nsToolbar }
        set { controller.nsToolbar = newValue }
    }

    public func updateToolbar(for viewController: UIViewController) {
        controller.updateToolbar(for: viewController)
    }
}
#endif
