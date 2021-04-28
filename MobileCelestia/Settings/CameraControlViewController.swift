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

import UIKit

import CelestiaCore

class CameraControlViewController: BaseTableViewController {
    struct Item {
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

    init() {
        super.init(style: .defaultGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension CameraControlViewController {
    func setup() {
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        tableView.register(SettingStepperCell.self, forCellReuseIdentifier: "Stepper")
        title = CelestiaString("Camera Control", comment: "")
    }
}

extension CameraControlViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return controlItems.count }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
            cell.title = CelestiaString("Reverse Direction", comment: "")
            return cell
        }
        let item = controlItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Stepper", for: indexPath) as! SettingStepperCell
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

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return CelestiaString("Long press on stepper to change orientation.", comment: "")
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let core = CelestiaAppCore.shared
        core.simulation.reverseObserverOrientation()
    }
}

private extension CameraControlViewController {
    func handleItemChange(index: Int, plus: Bool) {
        let core = CelestiaAppCore.shared
        let key = plus ? controlItems[index].plusKey : controlItems[index].minusKey
        if let prev = lastKey {
            if key == prev { return }
            core.keyUp(prev)
        }

        core.keyDown(key)
        lastKey = key
    }

    func handleStop() {
        if let key = lastKey {
            CelestiaAppCore.shared.keyUp(key)
            lastKey = nil
        }
    }
}
