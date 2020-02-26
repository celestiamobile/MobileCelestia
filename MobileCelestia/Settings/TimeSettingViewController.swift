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

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)
    private lazy var datePicker = UIDatePicker()

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

        datePicker.setValue(UIColor.darkLabel, forKey: "textColor")
        datePicker.addTarget(self, action: #selector(handleTimeChange), for: .valueChanged)
        tableView.tableHeaderView = datePicker

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
        tableView.register(SettingSwitchCell.self, forCellReuseIdentifier: "Switch")
        tableView.dataSource = self
        tableView.delegate = self
    }

    @objc private func handleTimeChange() {
        CelestiaAppCore.shared.simulation.time = datePicker.date
    }
}

extension TimeSettingViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        datePicker.setDate(CelestiaAppCore.shared.simulation.time, animated: false)
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let core = CelestiaAppCore.shared

        let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath) as! SettingSwitchCell
        cell.title = CelestiaString("Synchronize Time", comment: "")
        cell.enabled = core.synchTime
        cell.toggleBlock = { [weak self] (enabled) in
            core.synchTime = enabled
            self?.tableView.reloadData()
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
