//
// TimeSettingViewController.swift
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

class TimeSettingViewController: BaseTableViewController {
    private lazy var core = CelestiaAppCore.shared

    private lazy var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

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

private extension TimeSettingViewController {
    func setup() {
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        title = CelestiaString("Current Time", comment: "")
    }
}

extension TimeSettingViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        if indexPath.row == 0 {
            cell.title = CelestiaString("Select Time", comment: "")
            cell.detail = displayDateFormatter.string(from: core.simulation.time)
        } else {
            cell.title = CelestiaString("Set to Current Time", comment: "")
            cell.detail = nil
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let core = CelestiaAppCore.shared
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            let preferredFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMddHHmmss", options: 0, locale: Locale.current) ?? "yyyy/MM/dd HH:mm:ss"
            showDateInput(String(format: CelestiaString("Please enter the time in \"%s\" format.", comment: "").toLocalizationTemplate, preferredFormat), format: preferredFormat) { [weak self] (result) in
                guard let self = self else { return }

                guard let date = result else {
                    self.showError(CelestiaString("Unrecognized time string.", comment: ""))
                    return
                }

                self.core.simulation.time = date
                tableView.reloadData()
            }
        } else {
            core.receive(.currentTime)
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
