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

public class ObserverModeViewController: BaseTableViewController {
    private let executor: AsyncProviderExecutor

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
    private var referenceObject = Selection()
    private var targetObject = Selection()

    private enum Row {
        case coordinateSystem
        case referenceObjectName
        case targetObjectName
    }

    private var rows: [Row] = [.coordinateSystem, .referenceObjectName, .targetObjectName]

    public init(executor: AsyncProviderExecutor) {
        self.executor = executor
        super.init(style: .defaultGrouped)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    @objc private func applyObserverMode() {
        let system = coordinateSystem
        let ref = referenceObject
        let target = targetObject

        Task {
            await executor.run { appCore in
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
        windowTitle = title
        if #available(iOS 15, visionOS 1, *) {
            tableView.register(SelectionCell.self, forCellReuseIdentifier: "Selection")
        }
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(LinkFooterView.self, forHeaderFooterViewReuseIdentifier: "Footer")
        #if !os(visionOS)
        tableView.keyboardDismissMode = .interactive
        #endif

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CelestiaString("OK", comment: ""), style: .plain, target: self, action: #selector(applyObserverMode))
    }
}

extension ObserverModeViewController {
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        if #available(iOS 15, visionOS 1, *), row == .coordinateSystem {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Selection", for: indexPath) as! SelectionCell
            cell.title = CelestiaString("Coordinate System", comment: "Used in Flight Mode")
            cell.selectionData = SelectionCell.SelectionData(options: supportedCoordinateSystems.map { $0.name }, selectedIndex: supportedCoordinateSystems.firstIndex(of: coordinateSystem) ?? -1)
            cell.selectionChange = { [weak self] index in
                guard let self else { return }
                self.coordinateSystem = self.supportedCoordinateSystems[index]
                self.updateRows()
                self.tableView.reloadData()
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
        let title: String
        let detail: String
        let type: UITableViewCell.AccessoryType
        switch row {
        case .coordinateSystem:
            title = CelestiaString("Coordinate System", comment: "Used in Flight Mode")
            detail = coordinateSystem.name
            type = .none
        case .referenceObjectName:
            title = CelestiaString("Reference Object", comment: "Used in Flight Mode")
            detail = referenceObjectName
            type = .disclosureIndicator
        case .targetObjectName:
            title = CelestiaString("Target Object", comment: "Used in Flight Mode")
            detail = targetObjectName
            type = .disclosureIndicator
        }
        cell.title = title
        cell.detail = detail
        cell.accessoryType = type
        return cell
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Footer") as! LinkFooterView
        footer.info = LinkTextView.LinkInfo(text: CelestiaString("Flight mode decides how you move around in Celestia. Learn more…", comment: ""), links: [LinkTextView.Link(text: CelestiaString("Learn more…", comment: "Text for the link in Flight mode decides how you move around in Celestia. Learn more…"), link: "https://celestia.mobi/help/flight-mode?lang=\(AppCore.language)")])
        return footer
    }

    public override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch rows[indexPath.row] {
        case .coordinateSystem:
            if #available(iOS 15, visionOS 1, *) {
            } else {
                let vc = SelectionViewController(title: CelestiaString("Coordinate System", comment: "Used in Flight Mode"), options: supportedCoordinateSystems.map { $0.name }, selectedIndex: supportedCoordinateSystems.firstIndex(of: coordinateSystem), selectionChange: { [weak self] index in
                    guard let self = self else { return }
                    self.coordinateSystem = self.supportedCoordinateSystems[index]
                    self.updateRows()
                    self.tableView.reloadData()
                })
                navigationController?.pushViewController(vc, animated: true)
            }
        case .referenceObjectName:
            let searchController = SearchViewController(executor: executor) { [weak self] _, displayName, object in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
                self.referenceObjectName = displayName
                self.referenceObject = object
                self.tableView.reloadData()
            }
            navigationController?.pushViewController(searchController, animated: true)
        case .targetObjectName:
            let searchController = SearchViewController(executor: executor) { [weak self] _, displayName, object in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
                self.targetObjectName = displayName
                self.targetObject = object
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
            return CelestiaString("Free Flight", comment: "Flight mode, coordinate system")
        case .ecliptical:
            return CelestiaString("Follow", comment: "")
        case .bodyFixed:
            return CelestiaString("Sync Orbit", comment: "")
        case .phaseLock:
            return CelestiaString("Phase Lock", comment: "Flight mode, coordinate system")
        case .chase:
            return CelestiaString("Chase", comment: "")
        default:
            return ""
        }
    }
}
