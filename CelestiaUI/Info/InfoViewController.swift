// InfoViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import LinkPresentation
import UIKit

extension LPLinkMetadata: @unchecked @retroactive Sendable {}

public enum ObjectAction: Hashable, Sendable {
    case select
    case web(url: URL)
    case wrapped(action: CelestiaAction)
    case subsystem
    case alternateSurfaces
    case mark
}

public enum ExternalObjectAction {
    case subsystem
}

private extension ObjectAction {
    static var allCases: [ObjectAction] {
        return [.select] + CelestiaAction.allCases.map { ObjectAction.wrapped(action: $0) }
    }
}

final public class InfoViewController: UICollectionViewController {
    private enum Constants {
        static let buttonSpacing: CGFloat = GlobalConstants.pageMediumGapHorizontal
    }

    private enum Section {
        case content
        case buttons
    }

    private enum Item: Hashable {
        case description
        case link
        case button(ObjectAction)
        case cockpit
    }

    private let core: AppCore
    private let executor: AsyncProviderExecutor
    private let showNavigationTitle: Bool
    private let backgroundColor: UIColor?
    private var info: Selection
    private var bodyInfo: BodyInfo
    private var bodyInfoNeedsUpdating = false

    public var selectionHandler: ((Selection, ExternalObjectAction) -> Void)?

    private var linkMetaData: LPLinkMetadata?

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [unowned self] collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .description:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Description", for: indexPath) as! BodyDescriptionCell
                cell.update(with: self.bodyInfo, showTitle: !self.showNavigationTitle)
                return cell
            case .link:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LinkPreview", for: indexPath) as! LinkPreviewCell
                cell.setMetaData(self.linkMetaData)
                return cell
            case .cockpit:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Switch", for: indexPath) as! BodySwitchCell
                cell.title = CelestiaString("Use as Cockpit", comment: "Option to use a spacecraft as cockpit")
                let cockpit = self.info
                cell.enabled = cockpit == self.core.simulation.activeObserver.cockpit
                cell.toggleBlock = { [weak self] isEnabled in
                    guard let self else { return }
                    Task {
                        await self.executor.run { core in
                            core.simulation.activeObserver.cockpit = isEnabled ? cockpit : Selection()
                        }
                    }
                }
                return cell
            case let .button(action):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Action", for: indexPath) as! BodyActionCell
                cell.title = action.description
                switch action {
                case .alternateSurfaces:
                    cell.menu = self.menuForActions(alternativeSurfaceActions(selection: self.info))
                case .mark:
                    cell.menu = self.menuForActions(markActions(selection: self.info))
                default:
                    cell.menu = nil
                    break
                }
                cell.actionHandler = { [weak self] sourceView in
                    guard let self else { return }
                    self.handleAction(selection: self.info, action: action, sourceView: sourceView)
                }
                return cell
            }
        }
        return dataSource
    }()

    public init(info: Selection, core: AppCore, executor: AsyncProviderExecutor, showNavigationTitle: Bool, backgroundColor: UIColor?) {
        self.core = core
        self.executor = executor
        self.info = info
        self.showNavigationTitle = showNavigationTitle
        self.backgroundColor = backgroundColor
        self.bodyInfo = BodyInfo(selection: info, core: core)
        let layout = InfoCollectionLayout()
        layout.sectionInsetReference = .fromSafeArea

        super.init(collectionViewLayout: layout)

        if showNavigationTitle {
            title = bodyInfo.name
        }
        windowTitle = bodyInfo.name

        if #available(iOS 17, visionOS 1, *) {
            registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        reload()
    }

    public func setSelection(_ selection: Selection) {
        guard !info.isEqual(to: selection) else {
            return
        }
        linkMetaData = nil
        info = selection
        bodyInfoNeedsUpdating = true
        reload()
    }

    private func reload(fetchLinkData: Bool = true) {
        if bodyInfoNeedsUpdating {
            bodyInfo = BodyInfo(selection: info, core: core)
            if showNavigationTitle {
                title = bodyInfo.name
            }
            windowTitle = bodyInfo.name
            bodyInfoNeedsUpdating = false
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.content, .buttons])
        snapshot.appendItems([.description], toSection: .content)
        if info.body?.canBeUsedAsCockpit == true {
            snapshot.appendItems([.cockpit], toSection: .content)
        }
        if linkMetaData != nil {
            snapshot.appendItems([.link], toSection: .content)
        }
        var actions = ObjectAction.allCases
        if let urlString = info.webInfoURL, let url = URL(string: urlString) {
            actions.append(.web(url: url))
        }
        if let surfaces = info.body?.alternateSurfaceNames, surfaces.count > 0 {
            actions.append(.alternateSurfaces)
        }
        actions.append(.subsystem)
        actions.append(.mark)
        snapshot.appendItems(actions.map { .button($0) }, toSection: .buttons)

        if #available(iOS 15, visionOS 1, *) {
            dataSource.applySnapshotUsingReloadData(snapshot)
        } else {
            dataSource.apply(snapshot, animatingDifferences: false)
        }

        if fetchLinkData {
            guard let urlString = info.webInfoURL, let url = URL(string: urlString) else { return }

            let current = info
            let metaDataProvider = LPMetadataProvider()
            Task { [weak self] in
                do {
                    let metaData = try await metaDataProvider.startFetchingMetadata(for: url)
                    guard let self else { return }
                    guard self.info.isEqual(to: current) else { return }
                    self.linkMetaData = metaData
                    self.reload(fetchLinkData: false)
                } catch {}
            }
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 17, visionOS 1, *) {
        } else {
            if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
                collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        collectionView.collectionViewLayout.invalidateLayout()
    }
}

private extension InfoViewController {
    func setup() {
        if let backgroundColor {
            view.backgroundColor = backgroundColor
        }
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).estimatedItemSize = CGSize(width: 1, height: 1)
        collectionView.register(BodyDescriptionCell.self, forCellWithReuseIdentifier: "Description")
        collectionView.register(BodyActionCell.self, forCellWithReuseIdentifier: "Action")
        collectionView.register(LinkPreviewCell.self, forCellWithReuseIdentifier: "LinkPreview")
        collectionView.register(BodySwitchCell.self, forCellWithReuseIdentifier: "Switch")
        collectionView.dataSource = dataSource
    }
}

extension InfoViewController {
    private struct Action {
        let title: String
        let action: () -> Void
    }

    private func menuForActions(_ actions: [Action]) -> UIMenu? {
        guard !actions.isEmpty else { return nil }
        return UIMenu(children: actions.map({ action in
            return UIAction(title: action.title) { _ in
                action.action()
            }
        }))
    }

    private func markActions(selection: Selection) -> [Action] {
        let options = (0...MarkerRepresentation.crosshair.rawValue).map{ MarkerRepresentation(rawValue: $0)?.localizedTitle ?? "" } + [CelestiaString("Unmark", comment: "Unmark an object")]
        return options.enumerated().map { index, option in
            return Action(title: option) { [weak self] in
                guard let self else { return }
                if let marker = MarkerRepresentation(rawValue: UInt(index)) {
                    Task {
                        await self.executor.run { core in
                            core.simulation.universe.mark(selection, with: marker)
                            core.showMarkers = true
                        }
                    }
                } else {
                    Task {
                        await self.executor.run { core in
                            core.simulation.universe.unmark(selection)
                        }
                    }
                }
            }
        }
    }

    private func alternativeSurfaceActions(selection: Selection) -> [Action] {
        let alternativeSurfaces = selection.body?.alternateSurfaceNames ?? []
        return if alternativeSurfaces.isEmpty {
            []
        } else {
            ([CelestiaString("Default", comment: "")] + alternativeSurfaces).enumerated().map { index, option in
                return Action(title: option) { [weak self] in
                    guard let self else { return }
                    if index == 0 {
                        Task {
                            await self.executor.run { $0.simulation.activeObserver.displayedSurface = "" }
                        }
                        return
                    }
                    Task {
                        await self.executor.run { $0.simulation.activeObserver.displayedSurface = alternativeSurfaces[index - 1] }
                    }
                }
            }
        }
    }

    private func handleAction(selection: Selection, action: ObjectAction, sourceView: UIView) {
        switch action {
        case .select:
            Task {
                await self.executor.run { $0.simulation.selection = selection }
            }
        case .wrapped(let cac):
            Task {
                await self.executor.run { core in
                    core.simulation.selection = selection
                    core.receive(cac)
                }
            }
        case .web(let url):
            UIApplication.shared.open(url)
        case .subsystem:
            selectionHandler?(selection, .subsystem)
        case .alternateSurfaces:
            showActionSheet(title: CelestiaString("Alternate Surfaces", comment: "Alternative textures to display"), actions: alternativeSurfaceActions(selection: selection), from: sourceView)
        case .mark:
            showActionSheet(title: CelestiaString("Mark", comment: "Mark an object"), actions: markActions(selection: selection), from: sourceView)
        }
    }

    private func showActionSheet(title: String, actions: [Action], from sourceView: UIView) {
        guard !actions.isEmpty else { return }

        showSelection(title, options: actions.map({ $0.title }), source: .view(view: sourceView, sourceRect: nil)) { index in
            guard let index, index >= 0, index < actions.count else { return }
            actions[index].action()
        }
    }
}

class InfoCollectionLayout: UICollectionViewFlowLayout {
    private var attributesCache: [Int: UICollectionViewLayoutAttributes] = [:]

    // Only section 1 needs special handling
    private let twoColumnSection = 1

    override func prepare() {
        attributesCache = [:]

        guard let collectionView = self.collectionView else { super.prepare(); return }

        super.prepare()

        guard let dataSource = collectionView.dataSource else { return }
        let numberOfItems = dataSource.collectionView(collectionView, numberOfItemsInSection: twoColumnSection)
        var previousAttributes: UICollectionViewLayoutAttributes?
        for item in 0..<numberOfItems {
            let indexPath = IndexPath(item: item, section: twoColumnSection)
            guard let attributes = super.layoutAttributesForItem(at: indexPath) else { break }

            if item % 2 == 0 {
                previousAttributes = attributes
            } else {
                let height = max(previousAttributes!.size.height, attributes.size.height)
                previousAttributes!.size = CGSize(width: previousAttributes!.size.width, height: height)
                attributes.size = CGSize(width: attributes.size.width, height: height)
            }
            attributesCache[item] = attributes
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)

        var updatedAttributes: [UICollectionViewLayoutAttributes] = []
        attributes?.forEach({ attr in
            let ip = attr.indexPath
            if ip.section == twoColumnSection, let updatedAttr = attributesCache[ip.item] {
                updatedAttributes.append(updatedAttr)
            } else {
                updatedAttributes.append(attr)
            }
        })

        return updatedAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)

        var updatedAttributes = attributes
        if let ip = attributes?.indexPath, ip.section == twoColumnSection, let updated = attributesCache[ip.item] {
            updatedAttributes = updated
        }

        return updatedAttributes
    }
}

private extension ObjectAction {
    var description: String {
        switch self {
        case .select:
            return CelestiaString("Select", comment: "Select an object")
        case .web(_):
            return CelestiaString("Web Info", comment: "Web info for an object")
        case .wrapped(let action):
            return action.description
        case .subsystem:
            return CelestiaString("Subsystem", comment: "Subsystem of an object (e.g. planetarium system)")
        case .alternateSurfaces:
            return CelestiaString("Alternate Surfaces", comment: "Alternative textures to display")
        case .mark:
            return CelestiaString("Mark", comment: "Mark an object")
        }
    }
}

extension InfoViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = max(collectionView.bounds.width - collectionView.safeAreaInsets.left - collectionView.safeAreaInsets.right - 2 * GlobalConstants.pageMediumMarginHorizontal, 1)
        let height = collectionView.bounds.height
        if indexPath.section == 0 {
            return CGSize(width: width, height: max(height, 1))
        }
        return CGSize(width: max(collectionView.roundDownToPixel((width - Constants.buttonSpacing) / 2), 1), height: 1)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return GlobalConstants.pageMediumGapVertical
        }
        return Constants.buttonSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return GlobalConstants.pageMediumGapHorizontal
        }
        return Constants.buttonSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let horizontal = GlobalConstants.pageMediumMarginHorizontal
        if section == 0 {
            return UIEdgeInsets(top: GlobalConstants.pageMediumMarginVertical, left: horizontal, bottom: GlobalConstants.pageMediumGapVertical, right: horizontal)
        }
        return UIEdgeInsets(top: 0, left: horizontal, bottom: GlobalConstants.pageMediumMarginVertical, right: horizontal)
    }
}

public extension MarkerRepresentation {
    var localizedTitle: String {
        switch self {
        case .circle:
            return CelestiaString("Circle", comment: "Marker")
        case .triangle:
            return CelestiaString("Triangle", comment: "Marker")
        case .plus:
            return CelestiaString("Plus", comment: "Marker")
        case .X:
            return CelestiaString("X", comment: "Marker")
        case .crosshair:
            return CelestiaString("Crosshair", comment: "Marker")
        case .diamond:
            return CelestiaString("Diamond", comment: "Marker")
        case .disk:
            return CelestiaString("Disk", comment: "Marker")
        case .filledSquare:
            return CelestiaString("Filled Square", comment: "Marker")
        case .leftArrow:
            return CelestiaString("Left Arrow", comment: "Marker")
        case .upArrow:
            return CelestiaString("Up Arrow", comment: "Marker")
        case .rightArrow:
            return CelestiaString("Right Arrow", comment: "Marker")
        case .downArrow:
            return CelestiaString("Down Arrow", comment: "Marker")
        case .square:
            return CelestiaString("Square", comment: "Marker")
        @unknown default:
            return CelestiaString("Unknown", comment: "")
        }
    }
}
