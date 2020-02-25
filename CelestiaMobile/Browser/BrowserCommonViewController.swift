//
//  BrowserCommonViewController.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/25.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

class BrowserCommonViewController: UIViewController {
    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private let item: CelestiaBrowserItem

    private let selection: (CelestiaBrowserItem) -> Void

    init(item: CelestiaBrowserItem, selection: @escaping (CelestiaBrowserItem) -> Void) {
        self.item = item
        self.selection = selection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground

        title = item.name
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

private extension BrowserCommonViewController {
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

extension BrowserCommonViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return item.children.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let subitem = item.children[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = subitem.name
        cell.accessoryType = subitem.children.count == 0 ? .none : .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let subitem = item.children[indexPath.row]
        selection(subitem)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
