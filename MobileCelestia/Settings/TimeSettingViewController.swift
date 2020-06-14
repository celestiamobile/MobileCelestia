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

    private lazy var datePickerContainer = UIView()

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

        datePicker.translatesAutoresizingMaskIntoConstraints = false
        #if !targetEnvironment(macCatalyst)
        if datePicker.responds(to: NSSelectorFromString("_setTextColor:")) {
            datePicker.setValue(UIColor.darkLabel, forKey: "textColor")
        }
        #endif
        datePicker.addTarget(self, action: #selector(handleTimeChange), for: .valueChanged)

        datePickerContainer.addSubview(datePicker)
        #if targetEnvironment(macCatalyst)
        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: datePickerContainer.leadingAnchor, constant: 16),
            datePicker.trailingAnchor.constraint(equalTo: datePickerContainer.trailingAnchor, constant: -16),
            datePicker.topAnchor.constraint(equalTo: datePickerContainer.topAnchor, constant: 8),
            datePicker.bottomAnchor.constraint(equalTo: datePickerContainer.bottomAnchor, constant: -8),
        ])
        #else
        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: datePickerContainer.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: datePickerContainer.trailingAnchor),
            datePicker.topAnchor.constraint(equalTo: datePickerContainer.topAnchor),
            datePicker.bottomAnchor.constraint(equalTo: datePickerContainer.bottomAnchor),
        ])
        #endif

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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = CelestiaString("Set to Current Time", comment: "")

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let core = CelestiaAppCore.shared
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 0 {
            core.receive(.currentTime)
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return datePickerContainer
    }
}
