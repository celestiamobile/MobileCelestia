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
    private struct KeyAction {
        let title: String
        let minusKey: Int
        let plusKey: Int
    }

    private struct Section {
        let items: [Item]
        let footer: String?
    }

    private enum Item {
        case keyAction(KeyAction)
        case flightMode
        case reverseOrientation
    }

    private var sections: [Section] = [
        Section(items: [
            .keyAction(KeyAction(title: CelestiaString("Pitch", comment: "Camera control"), minusKey: 32, plusKey: 26)),
            .keyAction(KeyAction(title: CelestiaString("Yaw", comment: "Camera control"), minusKey: 28, plusKey: 30)),
            .keyAction(KeyAction(title: CelestiaString("Roll", comment: "Camera control"), minusKey: 31, plusKey: 33)),
        ], footer: CelestiaString("Long press on stepper to change orientation.", comment: "")),
        Section(items: [
            .keyAction(KeyAction(title: CelestiaString("Zoom (Distance)", comment: "Zoom in/out in Camera Control, this changes the relative distance to the object"), minusKey: 6, plusKey: 5)),
        ], footer: CelestiaString("Long press on stepper to zoom in/out.", comment: "")),
        Section(items: [.flightMode], footer: nil),
        Section(items: [.reverseOrientation], footer: nil),
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
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(StepperCell.self, forCellReuseIdentifier: "Stepper")
        tableView.rowHeight = UITableView.automaticDimension
        title = CelestiaString("Camera Control", comment: "Observer control")
        windowTitle = title
    }
}

extension CameraControlViewController {
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case let .keyAction(keyAction):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Stepper", for: indexPath) as! StepperCell
            cell.title = keyAction.title
            cell.selectionStyle = .none
            cell.changeBlock = { [unowned self] plus in
                self.handleKeyAction(keyAction, plus: plus)
            }
            cell.stopBlock = { [unowned self] in
                self.handleStop()
            }
            return cell
        case .flightMode:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
            cell.title = CelestiaString("Flight Mode", comment: "")
            cell.accessoryType = .disclosureIndicator
            return cell
        case .reverseOrientation:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
            cell.title = CelestiaString("Reverse Direction", comment: "Reverse camera direction, reverse travel direction")
            cell.accessoryType = .none
            return cell
        }
    }

    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case .keyAction:
            break
        case .flightMode:
            navigationController?.pushViewController(ObserverModeViewController(executor: executor), animated: true)
        case .reverseOrientation:
            Task {
                await executor.run { $0.simulation.reverseObserverOrientation() }
            }
        }
    }
}

private extension CameraControlViewController {
    private func handleKeyAction(_ keyAction: KeyAction, plus: Bool) {
        let key = plus ? keyAction.plusKey : keyAction.minusKey
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

    private func handleStop() {
        if let key = lastKey {
            Task {
                await executor.run { $0.keyUp(key) }
            }
            lastKey = nil
        }
    }
}
