// SearchViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

public protocol SearchContentViewController: UIViewController {
    var contentScrollView: UIScrollView? { get }
}

public class SearchViewController: UIViewController {
    #if !targetEnvironment(macCatalyst)
    private lazy var searchController = UISearchController(searchResultsController: nil)
    private var shouldActivate = true
    #endif

    private var fullMatch: Selection = Selection()

    private let selected: (_ viewController: SearchViewController, _ display: String, _ selection: Selection) -> Void

    private let executor: AsyncProviderExecutor
    private var currentSearchTerm: String?
    private var validSearchTerm: String?

    private lazy var resultViewController: SearchResultViewController = {
        return SearchResultViewController(selected: { [weak self] _, display, selection in
            guard let self else { return }
            #if !targetEnvironment(macCatalyst)
            self.searchController.searchBar.resignFirstResponder()
            #endif
            self.selected(self, display, selection)
        }, contentScrollViewChanged: { [weak self] scrollView in
            guard let self else { return }
            self.setContentScrollView(scrollView)
        })
    }()

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

    public override var minimumSheetHeight: CGFloat {
        return resultViewController.minimumSheetHeight
    }

    func installContentViewController(_ viewController: SearchContentViewController) {
        #if !targetEnvironment(macCatalyst)
        view.endEditing(true)
        #endif
        resultViewController.installContentViewController(viewController)
    }
}

private extension SearchViewController {
    func setUp() {
        title = CelestiaString("Search", comment: "")
        windowTitle = title

        install(resultViewController)

        #if !targetEnvironment(macCatalyst)
        // Configure search bar
        let searchBar = searchController.searchBar
        navigationItem.searchController = searchController

        searchBar.sizeToFit()

        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchBar.keyboardAppearance = .dark
        searchBar.delegate = self
        #endif
    }

    func searchTextUpdated(_ text: String?) {
        guard currentSearchTerm != text else { return }

        currentSearchTerm = text
        guard let text, !text.isEmpty else {
            validSearchTerm = ""
            fullMatch = Selection()
            resultViewController.updateResults(resultSections: [], rawResults: [])
            resultViewController.updateState(.empty)
            resultViewController.updateSearchState(false)
            return
        }

        Task {
            resultViewController.updateSearchState(true)
            if resultViewController.isEmpty {
                resultViewController.updateState(.loading)
            }
            let (sections, rawResults, fullMatch) = await self.search(with: text)
            guard text == currentSearchTerm else { return }
            validSearchTerm = text
            self.fullMatch = fullMatch
            self.resultViewController.updateResults(resultSections: sections, rawResults: rawResults)
            self.resultViewController.updateState(.results(empty: rawResults.isEmpty))
        }
    }

    func searchTextReturned(_ text: String?) {
        guard let text, !text.isEmpty, resultViewController.isEmpty else { return }
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

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchTextUpdated(nil)
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
        return ([SearchResultSection(section: .main, results: completions.map { SearchResult(completion: $0) })], completions, results.fullMatch)
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
