//
// ObserverModeViewController.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

class ObserverModeViewController: BaseTableViewController {
    @Injected(\.executor) private var executor

    private let supportedCoordinateSystems: [CoordinateSystem] = [
        .universal,
        .ecliptical,
        .bodyFixed,
        .phaseLock,
        .chase
    ]

    private var coordinateSystem: CoordinateSystem = .universal
    private var referenceObjectName = ""
    private var targetObjectName = ""

    private enum Row {
        case coordinateSystem
        case referenceObjectName
        case targetObjectName
    }

    private var rows: [Row] = [.coordinateSystem, .referenceObjectName, .targetObjectName]

    init() {
        super.init(style: .defaultGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    @objc private func applyObserverMode() {
        let system = coordinateSystem
        let refName = referenceObjectName
        let targetName = targetObjectName

        Task {
            await executor.run { appCore in
                let ref = refName.isEmpty ? Selection() : appCore.simulation.findObject(from: refName)
                let target = targetName.isEmpty ? Selection() : appCore.simulation.findObject(from: targetName)
                appCore.simulation.activeObserver.setFrame(coordinate: system, target: target, reference: ref)
            }
        }
    }

    private func updateRows() {
        switch coordinateSystem {
        case .universal:
            rows = [.coordinateSystem]
        case .ecliptical, .bodyFixed, .chase:
            rows = [.coordinateSystem, .referenceObjectName]
        case .phaseLock:
            rows = [.coordinateSystem, .referenceObjectName, .targetObjectName]
        default:
            rows = [.coordinateSystem]
        }
    }
}

private extension ObserverModeViewController {
    func setUp() {
        updateRows()

        navigationItem.backButtonTitle = ""
        title = CelestiaString("Flight Mode", comment: "")
        if #available(iOS 15.0, *) {
            tableView.register(SettingSelectionCell.self, forCellReuseIdentifier: "Selection")
        }
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(LinkFooterView.self, forHeaderFooterViewReuseIdentifier: "Footer")
        tableView.keyboardDismissMode = .interactive

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CelestiaString("OK", comment: ""), style: .plain, target: self, action: #selector(applyObserverMode))
    }
}

extension ObserverModeViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        if #available(iOS 15.0, *), row == .coordinateSystem {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Selection", for: indexPath) as! SettingSelectionCell
            cell.title = CelestiaString("Coordinate System", comment: "")
            cell.selectionData = SettingSelectionCell.SelectionData(options: supportedCoordinateSystems.map { $0.name }, selectedIndex: supportedCoordinateSystems.firstIndex(of: coordinateSystem) ?? -1)
            cell.selectionChange = { [weak self] index in
                guard let self else { return }
                self.coordinateSystem = self.supportedCoordinateSystems[index]
                self.updateRows()
                self.tableView.reloadData()
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        let title: String
        let detail: String
        let type: UITableViewCell.AccessoryType
        switch row {
        case .coordinateSystem:
            title = CelestiaString("Coordinate System", comment: "")
            detail = coordinateSystem.name
            type = .none
        case .referenceObjectName:
            title = CelestiaString("Reference Object", comment: "")
            detail = referenceObjectName
            type = .disclosureIndicator
        case .targetObjectName:
            title = CelestiaString("Target Object", comment: "")
            detail = targetObjectName
            type = .disclosureIndicator
        }
        cell.title = title
        cell.detail = detail
        cell.accessoryType = type
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Footer") as! LinkFooterView
        footer.info = LinkFooterView.LinkInfo(text: CelestiaString("Flight mode decides how you move around in Celestia. Learn more…", comment: ""), linkText: CelestiaString("Learn more…", comment: ""), link: "https://celestia.mobi/help/flight-mode?lang=\(AppCore.language)")
        return footer
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch rows[indexPath.row] {
        case .coordinateSystem:
            if #available(iOS 15.0, *) {
            } else {
                let vc = SettingSelectionViewController(title: CelestiaString("Coordinate System", comment: ""), options: supportedCoordinateSystems.map { $0.name }, selectedIndex: supportedCoordinateSystems.firstIndex(of: coordinateSystem), selectionChange: { [weak self] index in
                    guard let self = self else { return }
                    self.coordinateSystem = self.supportedCoordinateSystems[index]
                    self.updateRows()
                    self.tableView.reloadData()
                })
                navigationController?.pushViewController(vc, animated: true)
            }
        case .referenceObjectName:
            let searchController = SearchViewController(resultsInSidebar: false) { [weak self] name in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
                self.referenceObjectName = name
                self.tableView.reloadData()
            }
            navigationController?.pushViewController(searchController, animated: true)
        case .targetObjectName:
            let searchController = SearchViewController(resultsInSidebar: false) { [weak self] name in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
                self.targetObjectName = name
                self.tableView.reloadData()
            }
            navigationController?.pushViewController(searchController, animated: true)
        }
    }
}

private extension CoordinateSystem {
    var name: String {
        switch self {
        case .universal:
            return CelestiaString("Free Flight", comment: "")
        case .ecliptical:
            return CelestiaString("Follow", comment: "")
        case .bodyFixed:
            return CelestiaString("Sync Orbit", comment: "")
        case .phaseLock:
            return CelestiaString("Phase Lock", comment: "")
        case .chase:
            return CelestiaString("Chase", comment: "")
        default:
            return ""
        }
    }
}