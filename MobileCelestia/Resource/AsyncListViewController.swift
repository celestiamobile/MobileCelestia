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
    var imageURL: (URL, String)? { get }
}

class AsyncListViewController<T: AsyncListItem>: BaseTableViewController {
    class var showDisclosureIndicator: Bool { return true }
    class var useStandardUITableViewCell: Bool { return false }
    class var alwaysRefreshOnAppear: Bool { return false }

    private lazy var activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13, *) {
            return UIActivityIndicatorView(style: .large)
        } else {
            return UIActivityIndicatorView(style: .whiteLarge)
        }
    }()

    private lazy var refreshButton: UIButton = {
        if #available(iOS 15.0, *) {
            return UIButton(configuration: .plain())
        } else {
            return UIButton(type: .system)
        }
    }()

    var additionalItem: T?

    private var items: [T] = []
    private var hasMoreToLoad = true
    private var isLoading = false
    private var selection: (T) -> Void
    private var currentRequestID: UUID?
    private var isFirstAppear: Bool = true

    init(selection: @escaping (T) -> Void) {
        self.selection = selection
        super.init(style: Self.showDisclosureIndicator ? .defaultGrouped : .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isFirstAppear {
            isFirstAppear = false
            callRefresh()
        } else if Self.alwaysRefreshOnAppear {
            // Cancel previous request if any...
            currentRequestID = nil
            isLoading = false
            hasMoreToLoad = true
            items = []
            tableView.reloadData()
            callRefresh()
        }
    }

    func loadItems(pageStart: Int, pageSize: Int, success: @escaping ([T]) -> Void, failure: @escaping (Error) -> Void) {}

    @objc private func callRefresh() {
        loadNewItems()
    }

    private func loadNewItems() {
        guard hasMoreToLoad, !isLoading else { return }

        isLoading = true
        let pageStart = items.count
        let freshLoad = pageStart == 0
        let pageSize = freshLoad ? 40 : 20
        if freshLoad {
            startRefreshing()
        }
        let requestID = UUID()
        currentRequestID = requestID
        loadItems(pageStart: pageStart, pageSize: pageSize) { [weak self] newItems in
            guard let self = self else { return }
            guard self.currentRequestID == requestID else { return }
            if freshLoad {
                self.stopRefreshing(success: true)
            }
            self.hasMoreToLoad = newItems.count > 0
            self.isLoading = false
            self.items.append(contentsOf: newItems)
            if freshLoad {
                self.tableView.reloadData()
            } else {
                self.tableView.insertRows(at: (pageStart..<(pageStart + newItems.count)).map{ IndexPath(row: $0, section: 0) }, with: .automatic)
            }
        } failure: { [weak self] error in
            guard let self = self else { return }
            guard self.currentRequestID == requestID else { return }
            if freshLoad {
                self.stopRefreshing(success: false)
            }
            self.isLoading = false
        }
    }

    private func startRefreshing() {
        tableView.backgroundView = activityIndicator
        activityIndicator.startAnimating()
    }

    private func stopRefreshing(success: Bool) {
        tableView.backgroundView = success ? nil : refreshButton
        activityIndicator.stopAnimating()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return additionalItem == nil ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? items.count : additionalItem == nil ? 0 : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = indexPath.section == 0 ? items[indexPath.row] : additionalItem!
        if Self.useStandardUITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath)
            if #available(iOS 14, *) {
                var configuration = UIListContentConfiguration.sidebarCell()
                configuration.text = item.name
                cell.contentConfiguration = configuration
            } else {
                cell.textLabel?.text = item.name
            }
            cell.accessoryType = Self.showDisclosureIndicator ? .disclosureIndicator : .none
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.accessoryType = Self.showDisclosureIndicator ? .disclosureIndicator : .none
        cell.title = item.name
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            selection(items[indexPath.row])
        } else if let item = additionalItem {
            selection(item)
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == items.count - 1 {
            loadNewItems()
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

private extension AsyncListViewController {
    func setup() {
        if Self.useStandardUITableViewCell {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Text")
        } else {
            tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        }

        refreshButton.setTitle(CelestiaString("Refresh", comment: ""), for: .normal)
        refreshButton.addTarget(self, action: #selector(callRefresh), for: .touchUpInside)
    }
}
