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

import CelestiaCore
import UIKit

struct SearchResult {
    let name: String
}

struct SearchResultSection {
    let title: String?
    let results: [SearchResult]
}

public class SearchViewController: BaseTableViewController {
    private lazy var searchController = UISearchController(searchResultsController: nil)

    private let resultsInSidebar: Bool

    private var resultSections: [SearchResultSection] = []

    private let selected: (_ display: String, _ path: String) -> Void

    private var shouldActivate = true

    private let executor: AsyncProviderExecutor
    private var currentSearchTerm: String?
    private var validSearchTerm: String?

    private lazy var emptyView = EmptyHintView()
    private lazy var loadingView = UIActivityIndicatorView(style: .large)
    private lazy var emptyViewContainer = SafeAreaView(view: self.emptyView)
    private lazy var loadingViewContainer = SafeAreaView(view: self.loadingView)

    public init(resultsInSidebar: Bool, executor: AsyncProviderExecutor, selected: @escaping (_ display: String, _ path: String) -> Void) {
        self.resultsInSidebar = resultsInSidebar
        self.selected = selected
        self.executor = executor
        super.init(style: resultsInSidebar ? .defaultGrouped : .plain)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if shouldActivate {
            Task {
                try await Task.sleep(nanoseconds: 100000000)
                self.searchController.searchBar.becomeFirstResponder()
            }
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        shouldActivate = searchController.searchBar.isFirstResponder
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        emptyViewContainer.manualSafeAreaInsets = view.safeAreaInsets
        loadingViewContainer.manualSafeAreaInsets = view.safeAreaInsets
    }
}

private extension SearchViewController {
    func setUp() {
        title = CelestiaString("Search", comment: "")

        emptyViewContainer.manualSafeAreaInsets = view.safeAreaInsets
        loadingViewContainer.manualSafeAreaInsets = view.safeAreaInsets

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        if #available(iOS 15, *) {
            navigationItem.compactScrollEdgeAppearance = appearance
        }

        #if !targetEnvironment(macCatalyst)
        view.backgroundColor = .systemBackground
        #endif

        // Configure search bar
        let searchBar = searchController.searchBar
        navigationItem.searchController = searchController

        searchBar.sizeToFit()

        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchBar.keyboardAppearance = .dark
        searchBar.delegate = self

        tableView.keyboardDismissMode = .interactive
        tableView.register(resultsInSidebar ? UITableViewCell.self : TextCell.self, forCellReuseIdentifier: "Text")

        emptyView.title = CelestiaString("Find stars, DSOs, and nearby objects", comment: "")
        tableView.backgroundView = emptyViewContainer
    }

    func searchTextUpdated(_ text: String?) {
        currentSearchTerm = text
        guard let text, !text.isEmpty else {
            emptyView.title = CelestiaString("Find stars, DSOs, and nearby objects", comment: "")
            validSearchTerm = ""
            resultSections = []
            tableView.reloadData()
            loadingView.stopAnimating()
            tableView.backgroundView = emptyViewContainer
            return
        }

        Task {
            if resultSections.reduce(0, { $0 + $1.results.count }) == 0 {
                tableView.backgroundView = loadingViewContainer
                loadingView.startAnimating()
            }
            let results = await self.search(with: text)
            guard text == currentSearchTerm else { return }
            validSearchTerm = text
            self.resultSections = results
            self.tableView.reloadData()
            self.loadingView.stopAnimating()
            if results.reduce(0, { $0 + $1.results.count }) == 0 {
                self.emptyView.title = CelestiaString("No result found", comment: "")
                self.tableView.backgroundView = self.emptyViewContainer
            } else {
                self.tableView.backgroundView = nil
            }
        }
    }

    func searchTextReturned(_ text: String?) {
        guard let text, !text.isEmpty, resultSections.reduce(0, { $0 + $1.results.count }) == 0 else { return }
        itemSelected(with: text)
    }
}

extension SearchViewController: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchTextReturned(searchBar.text)
    }

    private func itemSelected(with name: String) {
        view.endEditing(true)

        selected(name, name)
    }
}

extension SearchViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        guard searchController.isActive else { return }
        searchTextUpdated(searchController.searchBar.text)
    }
}

extension SearchViewController {
    private func search(with text: String) async -> [SearchResultSection] {
        let completions = await executor.get {
            $0.simulation.completion(for: text)
        }
        return [SearchResultSection(title: nil, results: completions.map { SearchResult(name: $0) })]
    }
}

extension SearchViewController {
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return resultSections.count
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultSections[section].results.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
        cell.title = result.name
        return cell
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return resultSections[section].title
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let validSearchTerm else { return }
        guard indexPath.section < resultSections.count, indexPath.row < resultSections[indexPath.section].results.count else { return }

        let selection = resultSections[indexPath.section].results[indexPath.row]
        let name: String
        if let lastSeparatorIndex = validSearchTerm.lastIndex(of: "/") {
            name = String(validSearchTerm[validSearchTerm.startIndex...lastSeparatorIndex] + selection.name)
        } else {
            name = selection.name
        }
        selected(selection.name, name)
    }
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: GoToInputViewController.self).bundleIdentifier!
    fileprivate static let search = NSToolbarItem.Identifier.init("\(prefix).search")
}

extension SearchViewController: ToolbarAwareViewController {
    public func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier] {
        return [.search]
    }

    public func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        if itemIdentifier == .search {
            return NSToolbarItem.searchItem(with: .search, currentText: currentSearchTerm) { [weak self] text in
                guard let self else { return }
                self.searchTextUpdated(text)
            } returnHandler: { [weak self] text in
                guard let self else { return }
                self.searchTextReturned(text)
            }
        }
        return nil
    }
}
#endif
