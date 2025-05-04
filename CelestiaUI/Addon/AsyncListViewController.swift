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

protocol AsyncListItem: Sendable {
    var name: String { get }
    var imageURL: (URL, String)? { get }
}

class AsyncListViewController<T: AsyncListItem>: UICollectionViewController {
    class var showDisclosureIndicator: Bool { return true }
    class var useStandardUITableViewCell: Bool { return false }
    class var alwaysRefreshOnAppear: Bool { return false }

    private lazy var activityIndicator = UIActivityIndicatorView(style: .large)
    private lazy var refreshButton = ActionButtonHelper.newButton()

    var additionalItem: T?

    private var items: [T] = []
    private var hasMoreToLoad = true
    private var isLoading = false
    private var selection: (T) -> Void
    private var currentRequestID: UUID?
    private var isFirstAppear: Bool = true

    init(selection: @escaping (T) -> Void) {
        self.selection = selection
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: .init(appearance: Self.showDisclosureIndicator ? .defaultGrouped : .grouped)))
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
            collectionView.reloadData()
            callRefresh()
        }
    }

    func loadItems(pageStart: Int, pageSize: Int) async throws -> [T] {
        fatalError()
    }

    func emptyHintView() -> UIView? {
        return nil
    }

    @objc private func callRefresh() {
        Task {
            await loadNewItems()
        }
    }

    private func loadNewItems() async {
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
        do {
            collectionView.backgroundView = nil
            let newItems = try await loadItems(pageStart: pageStart, pageSize: pageSize)
            guard self.currentRequestID == requestID else { return }
            if freshLoad {
                self.stopRefreshing(success: true)
            }
            self.hasMoreToLoad = newItems.count > 0
            self.isLoading = false
            self.items.append(contentsOf: newItems)
            if freshLoad {
                self.collectionView.reloadData()
            } else {
                self.collectionView.insertItems(at: (pageStart..<(pageStart + newItems.count)).map{ IndexPath(row: $0, section: 0) })
            }
            self.collectionView.backgroundView = self.items.isEmpty ? self.emptyHintView() : nil
        } catch {
            guard self.currentRequestID == requestID else { return }
            if freshLoad {
                self.stopRefreshing(success: false)
            }
            self.isLoading = false
        }
    }

    private func startRefreshing() {
        collectionView.backgroundView = activityIndicator
        activityIndicator.startAnimating()
    }

    private func stopRefreshing(success: Bool) {
        collectionView.backgroundView = success ? nil : refreshButton
        activityIndicator.stopAnimating()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return additionalItem == nil ? 1 : 2
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? items.count : additionalItem == nil ? 0 : 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Text", for: indexPath) as! UICollectionViewListCell
        let item = indexPath.section == 0 ? items[indexPath.item] : additionalItem!
        var configuration: UIListContentConfiguration
        if Self.useStandardUITableViewCell {
            configuration = UIListContentConfiguration.sidebarCell()
        } else {
            configuration = UIListContentConfiguration.celestiaCell()
        }
        configuration.text = item.name
        cell.contentConfiguration = configuration
        cell.accessories = Self.showDisclosureIndicator ? [.disclosureIndicator()] : []
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            selection(items[indexPath.item])
        } else if let item = additionalItem {
            selection(item)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.item == items.count - 1 {
            Task {
                await loadNewItems()
            }
        }
    }
}

private extension AsyncListViewController {
    func setup() {
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "Text")

        refreshButton.setTitle(CelestiaString("Refresh", comment: "Button to refresh this list"), for: .normal)
        refreshButton.addTarget(self, action: #selector(callRefresh), for: .touchUpInside)
    }
}
