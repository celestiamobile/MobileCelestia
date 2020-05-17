//
//  SettingSliderViewController.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

class SettingSliderViewController: UIViewController {
    struct Item {
        let title: String
        let sliderItem: SettingSliderItem
    }

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private let item: Item

    init(item: Item) {
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

private extension SettingSliderViewController {
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
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension SettingSliderViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let core = CelestiaAppCore.shared
        let maxValue = item.sliderItem.maxValue
        let minValue = item.sliderItem.minValue
        let key = item.sliderItem.key

        let cell = tableView.dequeueReusableCell(withIdentifier: "Slider", for: indexPath) as! SettingSliderCell
        cell.title = item.title
        cell.value = ((core.value(forKey: key) as! Double) - minValue) / (maxValue - minValue)
        cell.valueChangeBlock = { [unowned self] (value) in
            let transformed = value * (maxValue - minValue) + minValue
            core.setValue(transformed, forKey: key)
            self.tableView.reloadData()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
}
