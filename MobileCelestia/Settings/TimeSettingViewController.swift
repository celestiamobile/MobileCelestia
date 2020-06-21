//
//  TimeSettingViewController.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/25.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

class TimeSettingViewController: UIViewController {

    private lazy var core = CelestiaAppCore.shared

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private let inputDateFormat = "yyyy/MM/dd HH:mm:ss"
    private lazy var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    private lazy var inputDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = self.inputDateFormat
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
            showTextInput(CelestiaString("Please enter the time in \(inputDateFormat) format.", comment: "")) { [weak self] (result) in
                guard let self = self, let res = result else { return }

                guard let date = self.inputDateFormatter.date(from: res) else {
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
