//
// GoToInputViewController.swift
//
// Copyright © 2021 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

protocol GoToInputItem {
    var title: String { get }
    var detail: String { get }
}

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

class GoToInputViewController: BaseTableViewController {
    private enum Constants {
        static let defaultLatitude: Float = 0
        static let defaultLongitude: Float = 0
        static let defaultDistance: Double = 8
    }

    struct DoubleValueItem: GoToInputItem {
        enum ValueType {
            case distance
        }
        let title: String
        let value: Double?
        let valueString: String?
        let formatter: NumberFormatter
        let type: ValueType

        var detail: String { return valueString ?? "" }
    }

    struct FloatValueItem: GoToInputItem {
        enum ValueType {
            case longitude
            case latitude
        }
        let title: String
        let value: Float?
        let valueString: String?
        let formatter: NumberFormatter
        let type: ValueType

        var detail: String { return valueString ?? "" }
    }

    @available(iOS 15, visionOS 1, *)
    struct LonLatItem: GoToInputItem {
        var title: String { return "" }
        var detail: String { return "" }
    }

    @available(iOS 15, visionOS 1, *)
    struct DistanceItem: GoToInputItem {
        var title: String { return "" }
        var detail: String { return "" }
    }

    struct UnitItem: GoToInputItem {
        var title: String { "" }

        var detail: String { unit.name }

        let unit: DistanceUnit
    }

    struct ObjectNameItem: GoToInputItem {
        var title: String { CelestiaString("Object", comment: "In eclipse finder, object to find eclipse with, or in go to") }

        var detail: String { name }

        let name: String
    }

    struct Section {
        let title: String?
        let items: [GoToInputItem]
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

    private var allSections: [Section] = []

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
        super.init(style: .defaultGrouped)
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
    func setUp() {
        title = CelestiaString("Go to Object", comment: "")
        windowTitle = title
        #if !os(visionOS)
        tableView.keyboardDismissMode = .interactive
        #endif
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        if #available(iOS 15, visionOS 1, *) {
            tableView.register(LongitudeLatitudeInputCell.self, forCellReuseIdentifier: "LonLat")
            tableView.register(DistanceInputCell.self, forCellReuseIdentifier: "Distance")
        }

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
        let distanceSection: Section
        let coordinateSection: Section
        if #available(iOS 15, visionOS 1, *) {
            distanceSection = Section(title: CelestiaString("Distance", comment: "Distance to the object (in Go to)"), items: [DistanceItem()])
            coordinateSection = Section(title: CelestiaString("Coordinates", comment: "Longitude and latitude (in Go to)"), items: [
                LonLatItem(),
            ])
        } else {
            distanceSection = Section(title: nil, items: [
                DoubleValueItem(title: CelestiaString("Distance", comment: "Distance to the object (in Go to)"), value: distance, valueString: distanceString, formatter: numberFormatter, type: .distance),
                UnitItem(unit: unit),
            ])
            coordinateSection = Section(title: CelestiaString("Coordinates", comment: "Longitude and latitude (in Go to)"), items: [
                FloatValueItem(title: CelestiaString("Latitude", comment: "Coordinates"), value: latitude, valueString: latitudeString, formatter: numberFormatter, type: .latitude),
                FloatValueItem(title: CelestiaString("Longitude", comment: "Coordinates"), value: longitude, valueString: longitudeString, formatter: numberFormatter, type: .longitude),
            ])
        }
        allSections = [
            Section(title: nil, items: [ObjectNameItem(name: displayName)]),
            coordinateSection,
            distanceSection,
        ]
        tableView.reloadData()
    }
}

extension GoToInputViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return allSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allSections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = allSections[indexPath.section].items[indexPath.row]
        if #available(iOS 15, visionOS 1, *), item is LonLatItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LonLat", for: indexPath) as! LongitudeLatitudeInputCell
            cell.model = LongitudeLatitudeInputCell.Model(longitude: longitude, latitude: latitude, longitudeString: longitudeString, latitudeString: latitudeString)
            cell.coordinatesChanged = { [weak self] longitude, latitude, longitudeString, latitudeString in
                guard let self else { return }
                self.longitude = longitude
                self.latitude = latitude
                self.longitudeString = longitudeString
                self.latitudeString = latitudeString
                self.validate()
            }
            return cell
        }
        if #available(iOS 15, visionOS 1, *), item is DistanceItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Distance", for: indexPath) as! DistanceInputCell
            cell.model = DistanceInputCell.Model(
                units: DistanceUnit.allCases.map({ $0.name }),
                selectedUnitIndex: DistanceUnit.allCases.firstIndex(of: unit)!,
                distanceValue: distance,
                distanceString: distanceString
            )
            cell.unitChanged = { [weak self] unitIndex in
                self?.unit = DistanceUnit.allCases[unitIndex]
            }
            cell.distanceChanged = { [weak self] distanceValue, distanceString in
                guard let self else { return }
                self.distance = distanceValue
                self.distanceString = distanceString
                self.validate()
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
        cell.title = item.title
        cell.detail = item.detail
        if item is DoubleValueItem || item is FloatValueItem {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return allSections[section].title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = allSections[indexPath.section].items[indexPath.row]
        if item is ObjectNameItem {
            objectNameHandler(self)
        } else if item is UnitItem {
            let vc = SelectionViewController(title: CelestiaString("Distance Unit", comment: ""), options: DistanceUnit.allCases.map { $0.name }, selectedIndex: DistanceUnit.allCases.firstIndex(of: unit), selectionChange: { [weak self] index in
                guard let self = self else { return }
                self.unit = DistanceUnit.allCases[index]
                self.reload()
            })
            navigationController?.pushViewController(vc, animated: true)
        } else if let valueItem = item as? DoubleValueItem {
            Task {
                if let text = await textInputHandler(self, item.title, item.detail, .decimalPad), let value = self.numberFormatter.number(from: text)?.doubleValue, value >= 0.0 {
                    switch valueItem.type {
                    case .distance:
                        self.distance = value
                        self.distanceString = self.numberFormatter.string(from: value)
                    }
                    self.validate()
                    self.reload()
                }
            }
        } else if let valueItem = item as? FloatValueItem {
            Task {
                if let text = await textInputHandler(self, item.title, item.detail, .decimalPad), let value = self.numberFormatter.number(from: text)?.floatValue {
                    switch valueItem.type {
                    case .longitude:
                        if value >= -180.0 && value <= 180.0 {
                            self.longitude = value
                            self.longitudeString = self.numberFormatter.string(from: value)
                        }
                    case .latitude:
                        if value >= -90.0 && value <= 90.0 {
                            self.latitude = value
                            self.latitudeString = self.numberFormatter.string(from: value)
                        }
                    }
                    self.validate()
                    self.reload()
                }
            }
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
