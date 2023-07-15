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
    private let singleRowBaseIndex = 1

    private struct Item {
        let title: String
        let minusKey: Int
        let plusKey: Int
    }

    private var controlItems: [Item] = [
        Item(title: CelestiaString("Pitch", comment: ""), minusKey: 32, plusKey: 26),
        Item(title: CelestiaString("Yaw", comment: ""), minusKey: 28, plusKey: 30),
        Item(title: CelestiaString("Roll", comment: ""), minusKey: 31, plusKey: 33),
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
        title = CelestiaString("Camera Control", comment: "")
    }
}

extension CameraControlViewController {
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= singleRowBaseIndex { return 1 }
        return controlItems.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == singleRowBaseIndex {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
            cell.title = CelestiaString("Flight Mode", comment: "")
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        if indexPath.section == singleRowBaseIndex + 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
            cell.title = CelestiaString("Reverse Direction", comment: "")
            cell.accessoryType = .none
            return cell
        }
        let item = controlItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Stepper", for: indexPath) as! StepperCell
        cell.title = item.title
        cell.selectionStyle = .none
        cell.changeBlock = { [unowned self] (plus) in
            self.handleItemChange(index: indexPath.row, plus: plus)
        }
        cell.stopBlock = { [unowned self] in
            self.handleStop()
        }
        return cell
    }

    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return CelestiaString("Long press on stepper to change orientation.", comment: "")
        }
        return nil
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == singleRowBaseIndex {
            navigationController?.pushViewController(ObserverModeViewController(executor: executor), animated: true)
            return
        }
        if indexPath.section == singleRowBaseIndex + 1 {
            Task {
                await executor.run { $0.simulation.reverseObserverOrientation() }
            }
            return
        }
    }
}

private extension CameraControlViewController {
    func handleItemChange(index: Int, plus: Bool) {
        let key = plus ? controlItems[index].plusKey : controlItems[index].minusKey
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
