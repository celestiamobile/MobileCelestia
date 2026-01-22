// GoToInputViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

extension DistanceUnit: @retroactive CaseIterable {
    public static let allCases: [DistanceUnit] = [.radii, .KM, .AU]
}

private extension DistanceUnit {
    var name: String {
        switch self {
        case .AU:
            return CelestiaString("au", comment: "Astronomical unit")
        case .KM:
            return CelestiaString("km", comment: "Unit")
        case .radii:
            return CelestiaString("radii", comment: "In Go to, specify the distance based on the object radius")
        @unknown default:
            fatalError()
        }
    }
}

class GoToInputViewController: UICollectionViewController {
    private enum Constants {
        static let defaultLatitude: Float = 0
        static let defaultLongitude: Float = 0
        static let defaultDistance: Double = 8
    }

    private enum Section {
        case object
        case coordinates
        case distance
    }

    private enum Item {
        case object
        case coordinates
        case distance
    }

    private let locationHandler: ((GoToLocation) -> Void)
    private let objectNameHandler: ((GoToInputViewController) -> Void)
    private let textInputHandler: (_ viewController: UIViewController, _ title: String, _ text: String, _ keyboardType: UIKeyboardType) async -> String?

    private lazy var displayName = ""
    private lazy var object = Selection()

    private var longitude: Float?
    private var longitudeString: String?
    private var latitude: Float?
    private var latitudeString: String?
    private var distance: Double?
    private var distanceString: String?

    private var unit: DistanceUnit = .radii

    private let executor: AsyncProviderExecutor

#if targetEnvironment(macCatalyst)
    private lazy var goToolbarItem: NSToolbarItem = {
        return NSToolbarItem(itemIdentifier: .go, buttonTitle: CelestiaString("Go", comment: "Go to an object"), target: self, action: #selector(go))
    }()
#endif

    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let cellRegistration = UICollectionView.CellRegistration<SelectableListCell, Item> { [unowned self] cell, _, itemIdentifier in
            var configuration: any UIContentConfiguration  = UIListContentConfiguration.celestiaValueCell()
            var selectable = false
            let accessories: [UICellAccessory]
            switch itemIdentifier {
            case .object:
                var cellConfiguration = UIListContentConfiguration.celestiaValueCell()
                cellConfiguration.text = CelestiaString("Object", comment: "In eclipse finder, object to find eclipse with, or in go to")
                cellConfiguration.secondaryText = self.displayName
                configuration = cellConfiguration
                selectable = true
                accessories = [.disclosureIndicator()]
            case .distance:
                configuration = DistanceInputConfiguration(
                    model: DistanceInputConfiguration.Model(
                        units: DistanceUnit.allCases.map({ $0.name }),
                        selectedUnitIndex: DistanceUnit.allCases.firstIndex(of: unit)!,
                        distanceValue: self.distance,
                        distanceString: self.distanceString
                    ),
                    directionalLayoutMargins: NSDirectionalEdgeInsets(top: GlobalConstants.listItemMediumMarginVertical, leading: GlobalConstants.listItemMediumMarginHorizontal, bottom: GlobalConstants.listItemMediumMarginVertical, trailing: GlobalConstants.listItemMediumMarginHorizontal)
                ) { [weak self] unitIndex in
                    guard let self else { return }
                    self.unit = DistanceUnit.allCases[unitIndex]
                } distanceChanged: { [weak self] distanceValue, distanceString in
                    guard let self else { return }
                    self.distance = distanceValue
                    self.distanceString = distanceString
                    self.validate()
                }
                accessories = []
            case .coordinates:
                configuration = LongitudeLatitudeInputConfiguration(
                    model: LongitudeLatitudeInputConfiguration.Model(longitude: self.longitude, latitude: self.latitude, longitudeString: self.longitudeString, latitudeString: self.latitudeString),
                    directionalLayoutMargins: NSDirectionalEdgeInsets(top: GlobalConstants.listItemMediumMarginVertical, leading: GlobalConstants.listItemMediumMarginHorizontal, bottom: GlobalConstants.listItemMediumMarginVertical, trailing: GlobalConstants.listItemMediumMarginHorizontal),
                    coordinatesChanged: { [weak self] longitude, latitude, longitudeString, latitudeString in
                        guard let self else { return }
                        self.longitude = longitude
                        self.latitude = latitude
                        self.longitudeString = longitudeString
                        self.latitudeString = latitudeString
                        self.validate()
                    })
                accessories = []
            }
            cell.contentConfiguration = configuration
            cell.selectable = selectable
            cell.accessories = accessories
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] supplementaryView, _, indexPath in
            var configuration = UIListContentConfiguration.groupedHeader()
            if let self, let section = self.dataSource.sectionIdentifier(for: indexPath.section) {
                switch section {
                case .object:
                    break
                case .coordinates:
                    configuration.text = CelestiaString("Coordinates", comment: "Longitude and latitude (in Go to)")
                case .distance:
                    configuration.text = CelestiaString("Distance", comment: "Distance to the object (in Go to)")
                }
            }
            supplementaryView.contentConfiguration = configuration
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self else { return nil }
            let section = self.dataSource.sectionIdentifier(for: indexPath.section)
            if kind == UICollectionView.elementKindSectionHeader {
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            }
            return nil
        }

        return dataSource
    }()

    init(
        executor: AsyncProviderExecutor,
        objectNameHandler: @escaping (GoToInputViewController) -> Void,
        locationHandler: @escaping ((GoToLocation) -> Void),
        textInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ text: String, _ keyboardType: UIKeyboardType) async -> String?
    ) {
        self.distance = Constants.defaultDistance
        self.longitude = Constants.defaultLongitude
        self.latitude = Constants.defaultLatitude
        self.executor = executor
        self.objectNameHandler = objectNameHandler
        self.locationHandler = locationHandler
        self.textInputHandler = textInputHandler
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
            if let self, let section = self.dataSource.sectionIdentifier(for: sectionIndex) {
                switch section {
                case .object:
                    configuration.headerMode = .none
                case .coordinates:
                    configuration.headerMode = .supplementary
                case .distance:
                    configuration.headerMode = .supplementary
                }
            }
            return .list(using: configuration, layoutEnvironment: environment)
        })
        self.distanceString = numberFormatter.string(from: Constants.defaultDistance)
        self.longitudeString = numberFormatter.string(from: Constants.defaultLongitude)
        self.latitudeString = numberFormatter.string(from: Constants.defaultLatitude)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    func updateObject(displayName: String, object: Selection) {
        self.displayName = displayName
        self.object = object
        reload()
    }
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: GoToInputViewController.self).bundleIdentifier!
    fileprivate static let go = NSToolbarItem.Identifier.init("\(prefix).go")
}

extension GoToInputViewController: ToolbarAwareViewController {
    func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier] {
        return [.go]
    }

    func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        if itemIdentifier == .go {
            return goToolbarItem
        }
        return nil
    }
}
#endif

private extension GoToInputViewController {
    private func setUp() {
        title = CelestiaString("Go to Object", comment: "")
        windowTitle = title
        #if !os(visionOS)
        collectionView.keyboardDismissMode = .interactive
        #endif
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CelestiaString("Go", comment: "Go to an object"), style: .plain, target: self, action: #selector(go))

        reload()
    }

    @objc private func go() {
        guard !object.isEmpty else {
            showError(CelestiaString("Object not found", comment: ""))
            return
        }
        locationHandler(GoToLocation(selection: object, longitude: longitude ?? Constants.defaultLongitude, latitude: latitude ?? Constants.defaultLatitude, distance: distance ?? Constants.defaultDistance, unit: unit))
    }

    private func reload() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.object, .coordinates, .distance])
        snapshot.appendItems([.object], toSection: .object)
        snapshot.appendItems([.coordinates], toSection: .coordinates)
        snapshot.appendItems([.distance], toSection: .distance)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

extension GoToInputViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .object:
            objectNameHandler(self)
        default:
            break
        }
    }
}

private extension GoToInputViewController {
    func validate() {
        if distance != nil && longitude != nil && latitude != nil {
            navigationItem.rightBarButtonItem?.isEnabled = true
            #if targetEnvironment(macCatalyst)
            goToolbarItem.isEnabled = true
            #endif
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
            #if targetEnvironment(macCatalyst)
            goToolbarItem.isEnabled = false
            #endif
        }
    }
}
