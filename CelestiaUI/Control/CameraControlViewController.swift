//
// CameraControlViewController.swift
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

public final class CameraControlViewController: BaseTableViewController {
    private struct Item {
        let title: String
        let minusKey: Int
        let plusKey: Int
    }

    private struct Section {
        let items: [Item]
        let footer: String
    }

    private var controlItems: [Section] = [
        Section(items: [
            Item(title: CelestiaString("Pitch", comment: "Camera control"), minusKey: 32, plusKey: 26),
            Item(title: CelestiaString("Yaw", comment: "Camera control"), minusKey: 28, plusKey: 30),
            Item(title: CelestiaString("Roll", comment: "Camera control"), minusKey: 31, plusKey: 33)
        ], footer: CelestiaString("Long press on stepper to change orientation.", comment: "")),
        Section(items: [
            Item(title: CelestiaString("Zoom (Distance)", comment: "Zoom in/out in Camera Control, this changes the relative distance to the object"), minusKey: 6, plusKey: 5),
        ], footer: CelestiaString("Long press on stepper to zoom in/out.", comment: "")),
    ]

    private var lastKey: Int?

    private let executor: AsyncProviderExecutor

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
}

private extension CameraControlViewController {
    func setUp() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Text")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Stepper")
        title = CelestiaString("Camera Control", comment: "Observer control")
        windowTitle = title
    }
}

extension CameraControlViewController {
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return controlItems.count + 2
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= controlItems.count { return 1 }
        return controlItems[section].items.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == controlItems.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath)
            var configuration = UIListContentConfiguration.celestiaCell()
            configuration.text = CelestiaString("Flight Mode", comment: "")
            cell.contentConfiguration = configuration
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        if indexPath.section == controlItems.count + 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath)
            var configuration = UIListContentConfiguration.celestiaCell()
            configuration.text = CelestiaString("Reverse Direction", comment: "Reverse camera direction, reverse travel direction")
            cell.contentConfiguration = configuration
            cell.accessoryType = .none
            return cell
        }
        let item = controlItems[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Stepper", for: indexPath)
        var configuration = UIListContentConfiguration.celestiaCell()
        configuration.text = item.title
        cell.contentConfiguration = configuration
        cell.selectionStyle = .none
//        cell.changeBlock = { [unowned self] (plus) in
//            self.handleItemChange(indexPath: indexPath, plus: plus)
//        }
//        cell.stopBlock = { [unowned self] in
//            self.handleStop()
//        }
        return cell
    }

    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section < controlItems.count {
            return controlItems[section].footer
        }
        return nil
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == controlItems.count {
            navigationController?.pushViewController(ObserverModeViewController(executor: executor), animated: true)
            return
        }
        if indexPath.section == controlItems.count + 1 {
            Task {
                await executor.run { $0.simulation.reverseObserverOrientation() }
            }
            return
        }
    }
}

private extension CameraControlViewController {
    func handleItemChange(indexPath: IndexPath, plus: Bool) {
        let item = controlItems[indexPath.section].items[indexPath.row]
        let key = plus ? item.plusKey : item.minusKey
        if let prev = lastKey {
            if key == prev { return }
            Task {
                await executor.run { $0.keyUp(prev) }
            }
        }

        Task {
            await executor.run { $0.keyDown(key) }
        }
        lastKey = key
    }

    func handleStop() {
        if let key = lastKey {
            Task {
                await executor.run { $0.keyUp(key) }
            }
            lastKey = nil
        }
    }
}
