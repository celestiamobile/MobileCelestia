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

extension DistanceUnit: CaseIterable {
    public static let allCases: [DistanceUnit] = [.radii, .KM, .AU]
}

private extension DistanceUnit {
    var name: String {
        switch self {
        case .AU:
            return "au"
        case .KM:
            return "km"
        case .radii:
            return "radii"
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

    struct LonLatItem: GoToInputItem {
        var title: String { return "" }
        var detail: String { return "" }
    }

    @available(iOS 15.0, *)
    struct DistanceItem: GoToInputItem {
        var title: String { return "" }
        var detail: String { return "" }
    }

    struct UnitItem: GoToInputItem {
        var title: String { "" }

        var detail: String { CelestiaString(unit.name, comment: "") }

        let unit: DistanceUnit
    }

    struct ObjectNameItem: GoToInputItem {
        var title: String { CelestiaString("Object", comment: "") }

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

    private var objectName: String = LocalizedString("Earth", "celestia-data")

    private var longitude: Float? = 0
    private var longitudeString: String?
    private var latitude: Float? = 0
    private var latitudeString: String?
    private var distance: Double?
    private var distanceString: String?

    private var unit: DistanceUnit = .radii

    private var allSections: [Section] = []

    private let executor: AsyncProviderExecutor

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

    func updateObjectName(_ name: String) {
        objectName = name
        reload()
    }
}

private extension GoToInputViewController {
    func setUp() {
        title = CelestiaString("Go to Object", comment: "")
        tableView.keyboardDismissMode = .interactive
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(LongitudeLatitudeInputCell.self, forCellReuseIdentifier: "LonLat")
        if #available(iOS 15.0, *) {
            tableView.register(DistanceInputCell.self, forCellReuseIdentifier: "Distance")
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CelestiaString("Go", comment: ""), style: .plain, target: self, action: #selector(go))

        reload()
    }

    @objc private func go() {
        Task {
            let objectName = self.objectName
            let selection = await executor.get { $0.simulation.findObject(from: objectName) }
            guard !selection.isEmpty else {
                showError(CelestiaString("Object not found", comment: ""))
                return
            }
            locationHandler(GoToLocation(selection: selection, longitude: longitude ?? Constants.defaultLongitude, latitude: latitude ?? Constants.defaultLatitude, distance: distance ?? Constants.defaultDistance, unit: unit))
        }
    }

    private func reload() {
        let distanceSection: Section
        if #available(iOS 15.0, *) {
            distanceSection = Section(title: CelestiaString("Distance", comment: ""), items: [DistanceItem()])
        } else {
            distanceSection = Section(title: nil, items: [
                DoubleValueItem(title: CelestiaString("Distance", comment: ""), value: distance, valueString: distanceString, formatter: numberFormatter, type: .distance),
                UnitItem(unit: unit)
            ])
        }
        allSections = [
            Section(title: nil, items: [ObjectNameItem(name: objectName)]),
            Section(title: CelestiaString("Coordinates", comment: ""), items: [
                LonLatItem(),
            ]),
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
        if item is LonLatItem {
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
        if #available(iOS 15.0, *), item is DistanceItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Distance", for: indexPath) as! DistanceInputCell
            cell.model = DistanceInputCell.Model(
                units: DistanceUnit.allCases.map({ CelestiaString($0.name, comment: "") }),
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
        cell.accessoryType = .disclosureIndicator
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
            let vc = SelectionViewController(title: CelestiaString("Distance Unit", comment: ""), options: DistanceUnit.allCases.map { CelestiaString($0.name, comment: "") }, selectedIndex: DistanceUnit.allCases.firstIndex(of: unit), selectionChange: { [weak self] index in
                guard let self = self else { return }
                self.unit = DistanceUnit.allCases[index]
                self.reload()
            })
            navigationController?.pushViewController(vc, animated: true)
        } else if let valueItem = item as? DoubleValueItem {
            Task {
                if let text = await textInputHandler(self, item.title, item.detail, .decimalPad), let value = self.numberFormatter.number(from: text)?.doubleValue {
                    switch valueItem.type {
                    case .distance:
                        self.distance = value
                        self.distanceString = self.numberFormatter.string(from: value)
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
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
}
