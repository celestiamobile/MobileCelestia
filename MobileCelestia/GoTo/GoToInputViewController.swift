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

private extension SimulationDistanceUnit {
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
    struct FloatValueItem: GoToInputItem {
        enum ValueType {
            case longitude
            case latitude
        }
        let title: String
        let value: Float
        let type: ValueType

        var detail: String { return String(format: "%.2f", value) }
    }

    struct DoubleValueItem: GoToInputItem {
        enum ValueType {
            case distance
        }
        let title: String
        let value: Double
        let type: ValueType

        var detail: String { return String(format: "%.2f", value) }
    }

    struct UnitItem: GoToInputItem {
        var title: String { "" }

        var detail: String { CelestiaString(unit.name, comment: "") }

        let unit: SimulationDistanceUnit
    }

    struct ProcceedItem: GoToInputItem {
        var title: String { CelestiaString("Go", comment: "") }

        var detail: String { "" }
    }

    struct ObjectNameItem: GoToInputItem {
        var title: String { CelestiaString("Object", comment: "") }

        var detail: String { name }

        let name: String
    }

    private let locationHandler: ((CelestiaGoToLocation) -> Void)

    private var objectName: String = LocalizedString("Earth", "celestia")
    private var longitude: Float = 0
    private var latitude: Float = 0

    private var distance: Double = 8
    private var unit: SimulationDistanceUnit = .radii

    private let core = CelestiaAppCore.shared

    private static let availableUnits: [SimulationDistanceUnit] = [.radii, .KM, .AU]

    private var allSections: [[GoToInputItem]] = []

    init(locationHandler: @escaping ((CelestiaGoToLocation) -> Void)) {
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
}

private extension GoToInputViewController {
    func setUp() {
        title = CelestiaString("Go to Object", comment: "")
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")

        reload()
    }

    private func reload() {
        allSections = [
            [ObjectNameItem(name: objectName)],
            [
                FloatValueItem(title: CelestiaString("Longitude", comment: ""), value: longitude, type: .longitude),
                FloatValueItem(title: CelestiaString("Latitude", comment: ""), value: latitude, type: .latitude)
            ],
            [
                DoubleValueItem(title: CelestiaString("Distance", comment: ""), value: distance, type: .distance),
                UnitItem(unit: unit)
            ],
            [ProcceedItem()]
        ]
        tableView.reloadData()
    }
}

extension GoToInputViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return allSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allSections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = allSections[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = item.title
        cell.detail = item.detail

        if item is ProcceedItem {
            #if targetEnvironment(macCatalyst)
            cell.titleColor = cell.tintColor
            #else
            cell.titleColor = UIColor.themeLabel
            #endif
        } else {
            cell.titleColor = UIColor.darkLabel
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = allSections[indexPath.section][indexPath.row]
        if let objectItem = item as? ObjectNameItem {
            showTextInput(CelestiaString("Please enter an object name.", comment: ""), text: objectItem.name) { [weak self] text in
                guard let self = self else { return }
                guard let objectName = text else { return }
                self.objectName = objectName
                self.reload()
            }
        } else if item is UnitItem {
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            showSelection(nil, options: Self.availableUnits.map({ CelestiaString($0.name, comment: "") }), sourceView: cell, sourceRect: cell.bounds) { [weak self] index in
                guard let self = self else { return }
                guard let newIndex = index else { return }
                self.unit = Self.availableUnits[newIndex]
                self.reload()
            }
        } else if let valueItem = item as? DoubleValueItem {
            showTextInput("", text: item.detail) { [weak self] string in
                guard let self = self else { return }
                guard let newString = string, let value = Double(newString) else { return }
                switch valueItem.type {
                case .distance:
                    self.distance = value
                }
                self.reload()
            }
        } else if let valueItem = item as? FloatValueItem {
            showTextInput("", text: item.detail) { [weak self] string in
                guard let self = self else { return }
                guard let newString = string, let value = Float(newString) else { return }
                switch valueItem.type {
                case .longitude:
                    self.longitude = value
                case .latitude:
                    self.latitude = value
                }
                self.reload()
            }
        } else if item is ProcceedItem {
            let selection = core.simulation.findObject(from: objectName)
            guard !selection.isEmpty else {
                showError(CelestiaString("Object not found", comment: ""))
                return
            }
            locationHandler(CelestiaGoToLocation(selection: selection, longitude: longitude, latitude: latitude, distance: distance, unit: unit))
        }
    }
}
