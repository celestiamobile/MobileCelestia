//
// SearchViewController.swift
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

struct SearchResult {
    let name: String
}

struct SearchResultSection {
    let title: String?
    let results: [SearchResult]
}

class SearchViewController: BaseTableViewController {
    private lazy var searchController = UISearchController(searchResultsController: nil)

    private let resultsInSidebar: Bool

    private var searchQueue = OperationQueue()

    private var resultSections: [SearchResultSection] = []

    private let selected: (String) -> Void

    private var shouldActivate = true

    @Injected(\.appCore) private var core

    init(resultsInSidebar: Bool, selected: @escaping (String) -> Void) {
        self.resultsInSidebar = resultsInSidebar
        self.selected = selected
        super.init(style: resultsInSidebar ? .defaultGrouped : .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if shouldActivate {
            Task {
                try await Task.sleep(seconds: 0.1)
                self.searchController.searchBar.becomeFirstResponder()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        shouldActivate = searchController.searchBar.isFirstResponder
    }

    deinit {
        searchQueue.cancelAllOperations()
    }
}

private extension SearchViewController {
    func setUp() {
        title = CelestiaString("Search", comment: "")

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        if #available(iOS 15, *) {
            navigationItem.compactScrollEdgeAppearance = appearance
        }

        #if !targetEnvironment(macCatalyst)
        view.backgroundColor = .darkBackground
        #endif

        searchQueue.maxConcurrentOperationCount = 1

        // Configure search bar
        let searchBar = searchController.searchBar
        if resultsInSidebar {
            navigationItem.titleView = searchBar
        } else {
            navigationItem.searchController = searchController
        }

        searchBar.sizeToFit()

        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchBar.keyboardAppearance = .dark
        searchBar.delegate = self

        tableView.keyboardDismissMode = .interactive
        tableView.register(resultsInSidebar ? UITableViewCell.self : SettingTextCell.self, forCellReuseIdentifier: "Text")
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let text = searchBar.text, !text.isEmpty, resultSections.reduce(0, { $0 + $1.results.count }) == 0 else { return }
        itemSelected(with: text)
    }

    private func itemSelected(with name: String) {
        view.endEditing(true)

        selected(name)
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.isActive else { return }

        guard let text = searchController.searchBar.text, !text.isEmpty else {
            resultSections = []
            tableView.reloadData()
            return
        }

        searchQueue.cancelAllOperations()
        searchQueue.addOperation { [weak self] in
            guard let self = self else { return }
            let results = self.search(with: text)
            Task.detached { @MainActor in
                guard text == self.searchController.searchBar.text else { return }
                self.resultSections = results
                self.tableView.reloadData()
            }
        }
    }
}

extension SearchViewController {
    private func search(with text: String) -> [SearchResultSection] {
        let simulation = core.simulation
        return [SearchResultSection(title: nil, results: simulation.completion(for: text).map { SearchResult(name: $0) })]
    }
}

extension SearchViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return resultSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultSections[section].results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = resultSections[indexPath.section].results[indexPath.row]
        if resultsInSidebar {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath)
            if #available(iOS 14.0, *) {
                var configuration = UIListContentConfiguration.sidebarCell()
                configuration.text = result.name
                cell.contentConfiguration = configuration
            } else {
                cell.textLabel?.text = result.name
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = result.name
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return resultSections[section].title
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selection = resultSections[indexPath.section].results[indexPath.row]
        selected(selection.name)
    }
}
