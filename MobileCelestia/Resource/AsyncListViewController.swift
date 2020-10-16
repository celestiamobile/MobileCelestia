//
// AsyncListViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

protocol AsyncListItem {
    var name: String { get }
}

class AsyncListViewController<T: AsyncListItem>: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var tableView = UITableView(frame: .zero, style: .grouped)

    private var activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    private var refreshButton = UIButton(type: .system)

    private var items: [T] = []
    private var selection: (T) -> Void

    init(selection: @escaping (T) -> Void) {
        self.selection = selection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground

        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        callRefresh()
    }

    func refresh(success: @escaping ([T]) -> Void, failure: @escaping (String) -> Void) {}

    @objc private func callRefresh() {
        startRefreshing()
        refresh { [weak self] (items) in
            self?.items = items
            self?.tableView.reloadData()
            self?.stopRefreshing(success: true)
        } failure: { [weak self] error in
            self?.stopRefreshing(success: false)
            self?.showError(error)
        }
    }

    func startRefreshing() {
        refreshButton.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    func stopRefreshing(success: Bool) {
        refreshButton.isHidden = success
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {   return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = items[indexPath.row].name
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        selection(items[indexPath.row])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

private extension AsyncListViewController {
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

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        // TODO: Localization
        refreshButton.setTitle("Refresh", for: .normal)
        refreshButton.setTitleColor(.darkLabel, for: .normal)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.addTarget(self, action: #selector(callRefresh), for: .touchUpInside)
        view.addSubview(refreshButton)

        NSLayoutConstraint.activate([
            refreshButton.topAnchor.constraint(equalTo: view.topAnchor),
            refreshButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            refreshButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
