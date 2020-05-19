//
//  SettingCommonViewController.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

class SettingCommonViewController: UIViewController {
    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private let item: SettingCommonItem

    init(item: SettingCommonItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground

        title = item.title
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

private extension SettingCommonViewController {
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

        tableView.register(SettingSliderCell.self, forCellReuseIdentifier: "Slider")
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Action")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension SettingCommonViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return item.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return item.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = item.sections[indexPath.section].rows[indexPath.row]
        let core = CelestiaAppCore.shared

        switch row.type {
        case .slider(let item):
            let maxValue = item.maxValue
            let minValue = item.minValue
            let key = item.key
            let cell = tableView.dequeueReusableCell(withIdentifier: "Slider", for: indexPath) as! SettingSliderCell
            cell.title = row.name
            cell.value = ((core.value(forKey: key) as! Double) - minValue) / (maxValue - minValue)
            cell.valueChangeBlock = { [unowned self] (value) in
                let transformed = value * (maxValue - minValue) + minValue
                core.setValue(transformed, forKey: key)
                self.tableView.reloadData()
            }
            return cell
        case .action(_):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Action", for: indexPath) as! SettingTextCell
            cell.title = row.name
            return cell
        default:
            fatalError("SettingCommonViewController cannot handle this type of item")
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = item.sections[indexPath.section].rows[indexPath.row].type
        switch rowType {
        case .action(let item):
            tableView.deselectRow(at: indexPath, animated: true)
            CelestiaAppCore.shared.charEnter(item.action)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType = item.sections[indexPath.section].rows[indexPath.row].type
        switch rowType {
        case .slider(_):
            return 88
        default:
            return 44
        }
    }
}
