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

class TimeSettingViewController: UIViewController {

    private lazy var core = CelestiaAppCore.shared

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private lazy var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground

        title = CelestiaString("Current Time", comment: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension TimeSettingViewController {
    func setup() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.separatorColor = .darkSeparator

        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension TimeSettingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
