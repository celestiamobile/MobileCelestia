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
    let completion: Completion
}

struct SearchResultSection {
    let title: String?
    let results: [SearchResult]
}

public class SearchViewController: UIViewController {
    #if !targetEnvironment(macCatalyst)
    private lazy var searchController = UISearchController(searchResultsController: nil)
    private var shouldActivate = true
    #endif

    private var resultSections: [SearchResultSection] = []
    private var rawResults: [Completion] = []
    private var fullMatch: Selection = Selection()

    private let selected: (_ viewController: SearchViewController, _ display: String, _ selection: Selection) -> Void

    private let executor: AsyncProviderExecutor
    private var currentSearchTerm: String?
    private var validSearchTerm: String?

    private lazy var emptyView = EmptyHintView()
    private lazy var loadingView = UIActivityIndicatorView(style: .large)
    private lazy var emptyViewContainer = SafeAreaView(view: emptyView)
    private lazy var loadingViewContainer = SafeAreaView(view: loadingView)

    private var contentViewController: UIViewController?

    private lazy var resultViewController: BaseTableViewController = {
        return BaseTableViewController(style: .plain)
    }()

    private var tableView: UITableView {
        return resultViewController.tableView
    }

    private enum State: Hashable {
        case empty
        case loading
        case results(empty: Bool)
    }

    private var state: State = .empty
    private var isSearchActive: Bool = false

    public init(executor: AsyncProviderExecutor, selected: @escaping (_ viewController: SearchViewController, _ display: String, _ selection: Selection) -> Void) {
        self.selected = selected
        self.executor = executor
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        let containerView = UIView()
        #if !os(visionOS)
        containerView.backgroundColor = .systemBackground
        #endif
        view = containerView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    #if !targetEnvironment(macCatalyst)
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
    #endif

    private func updateState(_ newState: State) {
        guard newState != state else { return }
        state = newState

        reload()
    }

    private func updateSearchState(_ isActive: Bool) {
        guard isActive != isSearchActive else { return }
        isSearchActive = isActive

        reload()
    }

    private func reload() {
        switch state {
        case .empty:
            resultViewController.view.isHidden = true
            loadingView.stopAnimating()
            loadingViewContainer.isHidden = true
            emptyView.title = CelestiaString("Find stars, DSOs, and nearby objects", comment: "")
            emptyViewContainer.isHidden = false
        case .loading:
            resultViewController.view.isHidden = true
            emptyViewContainer.isHidden = true
            loadingViewContainer.isHidden = false
            loadingView.startAnimating()
        case .results(let empty):
            resultViewController.view.isHidden = empty
            emptyView.title = empty ? CelestiaString("No result found", comment: "") : nil
            emptyViewContainer.isHidden = !empty
            loadingView.stopAnimating()
            loadingViewContainer.isHidden = true
        }

        if let contentViewController {
            if !isSearchActive {
                loadingView.stopAnimating()
                resultViewController.view.isHidden = true
                emptyViewContainer.isHidden = true
                loadingViewContainer.isHidden = true

                contentViewController.view.isHidden = false
                view.sendSubviewToBack(contentViewController.view)
            } else {
                contentViewController.view.isHidden = true
            }
        }
    }

    func installContentViewController(_ viewController: UIViewController) {
        if let contentViewController {
            contentViewController.remove()
            self.contentViewController = nil
        }

        install(viewController)
        contentViewController = viewController

        #if !targetEnvironment(macCatalyst)
        view.endEditing(true)
        #endif

        isSearchActive = false

        reload()
    }
}

private extension SearchViewController {
    func setUp() {
        title = CelestiaString("Search", comment: "")
        windowTitle = title

        install(resultViewController)

        for emptyView in [emptyViewContainer, loadingViewContainer] {
            #if !os(visionOS)
            emptyView.backgroundColor = .systemBackground
            #endif
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(emptyView)

            NSLayoutConstraint.activate([
                emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                emptyView.topAnchor.constraint(equalTo: view.topAnchor),
                emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        if #available(iOS 15, visionOS 1, *) {
            navigationItem.compactScrollEdgeAppearance = appearance
        }

        #if !targetEnvironment(macCatalyst)
        #if !os(visionOS)
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

        #if !os(visionOS)
        tableView.keyboardDismissMode = .interactive
        #endif
        #endif

        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")

        tableView.dataSource = self
        tableView.delegate = self

        reload()
    }

    func searchTextUpdated(_ text: String?) {
        guard currentSearchTerm != text else { return }

        currentSearchTerm = text
        guard let text, !text.isEmpty else {
            validSearchTerm = ""
            rawResults = []
            resultSections = []
            fullMatch = Selection()
            tableView.reloadData()
            loadingView.stopAnimating()
            updateState(.empty)
            updateSearchState(false)
            return
        }

        Task {
            updateSearchState(true)
            if rawResults.isEmpty {
                updateState(.loading)
            }
            let (sections, rawResults, fullMatch) = await self.search(with: text)
            guard text == currentSearchTerm else { return }
            validSearchTerm = text
            self.resultSections = sections
            self.rawResults = rawResults
            self.fullMatch = fullMatch
            self.tableView.reloadData()
            self.updateState(.results(empty: rawResults.isEmpty))
        }
    }

    func searchTextReturned(_ text: String?) {
        guard let text, !text.isEmpty, resultSections.reduce(0, { $0 + $1.results.count }) == 0 else { return }
        itemSelected(with: text)
    }

    private func itemSelected(with name: String) {
        selected(self, name, fullMatch)
    }
}

#if !targetEnvironment(macCatalyst)
extension SearchViewController: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchTextReturned(searchBar.text)
    }
}

extension SearchViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        searchTextUpdated(searchController.searchBar.text)
    }
}
#endif

extension SearchViewController {
    private func search(with text: String) async -> (results: [SearchResultSection], rawResults: [Completion], fullMatch: Selection) {
        let results: (completions: [Completion], fullMatch: Selection) = await executor.get { core in
            let completions = core.simulation.completion(for: text)
            let fullMatch = core.simulation.findObject(from: text)
            return (completions, fullMatch)
        }
        let completions = results.completions
        return ([SearchResultSection(title: nil, results: completions.map { SearchResult(completion: $0) })], completions, results.fullMatch)
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return resultSections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultSections[section].results.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = resultSections[indexPath.section].results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
        cell.title = result.completion.name
        return cell
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return resultSections[section].title
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let validSearchTerm else { return }
        guard indexPath.section < resultSections.count, indexPath.row < resultSections[indexPath.section].results.count else { return }

        let selection = resultSections[indexPath.section].results[indexPath.row]
        #if !targetEnvironment(macCatalyst)
        searchController.searchBar.resignFirstResponder()
        #endif
        selected(self, selection.completion.name, selection.completion.selection)
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
            } searchStartHandler: {} searchEndHandler: {}
        }
        return nil
    }
}
#endif
