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
    public static var allCases: [DistanceUnit] = [.radii, .KM, .AU]
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
    struct DoubleValueItem: GoToInputItem {
        enum ValueType {
            case distance
        }
        let title: String
        let value: Double
        let formatter: NumberFormatter
        let type: ValueType

        var detail: String { return formatter.string(from: NSNumber(value: value)) ?? "" }
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

    private var objectName: String = LocalizedString("Earth", "celestia-data")
    private var longitude: Float = 0
    private var latitude: Float = 0

    private var distance: Double = 8
    private var unit: DistanceUnit = .radii

    @Injected(\.appCore) private var core

    private var allSections: [Section] = []

    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    init(objectNameHandler: @escaping (GoToInputViewController) -> Void, locationHandler: @escaping ((GoToLocation) -> Void)) {
        self.objectNameHandler = objectNameHandler
        self.locationHandler = locationHandler
        super.init(style: .defaultGrouped)
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
        navigationItem.backButtonTitle = ""
        title = CelestiaString("Go to Object", comment: "")
        tableView.keyboardDismissMode = .interactive
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(LongitudeLatitudeInputCell.self, forCellReuseIdentifier: "LonLat")
        if #available(iOS 15.0, *) {
            tableView.register(DistanceInputCell.self, forCellReuseIdentifier: "Distance")
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CelestiaString("Go", comment: ""), style: .plain, target: self, action: #selector(go))

        reload()
    }

    @objc private func go() {
        let selection = core.simulation.findObject(from: objectName)
        guard !selection.isEmpty else {
            showError(CelestiaString("Object not found", comment: ""))
            return
        }
        locationHandler(GoToLocation(selection: selection, longitude: longitude, latitude: latitude, distance: distance, unit: unit))
    }

    private func reload() {
        let distanceSection: Section
        if #available(iOS 15.0, *) {
            distanceSection = Section(title: CelestiaString("Distance", comment: ""), items: [DistanceItem()])
        } else {
            distanceSection = Section(title: nil, items: [
                DoubleValueItem(title: CelestiaString("Distance", comment: ""), value: distance, formatter: numberFormatter, type: .distance),
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
            cell.model = LongitudeLatitudeInputCell.Model(longitude: longitude, latitude: latitude)
            cell.coordinatesChanged = { [weak self] longitude, latitude in
                guard let self = self else { return }
                self.longitude = longitude
                self.latitude = latitude
            }
            return cell
        }
        if #available(iOS 15.0, *), item is DistanceItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Distance", for: indexPath) as! DistanceInputCell
            cell.model = DistanceInputCell.Model(
                units: DistanceUnit.allCases.map({ CelestiaString($0.name, comment: "") }),
                selectedUnitIndex: DistanceUnit.allCases.firstIndex(of: unit)!,
                distance: distance
            )
            cell.unitChanged = { [weak self] unitIndex in
                self?.unit = DistanceUnit.allCases[unitIndex]
            }
            cell.distanceChanged = { [weak self] distance in
                self?.distance = distance
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = item.title
        cell.detail = item.detail
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
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            showSelection(nil, options: DistanceUnit.allCases.map({ CelestiaString($0.name, comment: "") }), source: .view(view: cell, sourceRect: nil)) { [weak self] index in
                guard let self = self else { return }
                guard let newIndex = index else { return }
                self.unit = DistanceUnit.allCases[newIndex]
                self.reload()
            }
        } else if let valueItem = item as? DoubleValueItem {
            showTextInput(item.title, text: item.detail, keyboardType: .decimalPad) { [weak self] string in
                guard let self = self else { return }
                guard let newString = string, let value = self.numberFormatter.number(from: newString)?.doubleValue ?? Double(newString) else { return }
                switch valueItem.type {
                case .distance:
                    self.distance = value
                }
                self.reload()
            }
        }
    }
}
