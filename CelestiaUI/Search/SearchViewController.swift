// SearchViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaFoundation
import UIKit

public protocol SearchContentViewController: UIViewController {
    var contentScrollView: UIScrollView? { get }
}

public class SearchViewController: UIViewController {
    private var shouldActivate = true
    #if targetEnvironment(macCatalyst)
    private weak var searchToolbarItem: NSToolbarItem?
    private var isSearchViewVisible = false
    #else
    private lazy var searchController = UISearchController(searchResultsController: nil)
    private var isSearchPresented = false
    private var pendingSearchFocus = false
    var cancelHandler: (() -> Void)?
    var searchActivationHandler: (() -> Void)?
    var sheetCloseButtonItem: UIBarButtonItem?
    #endif

    private var fullMatch: Selection = Selection()

    private let selected: (_ viewController: SearchViewController, _ display: String, _ selection: Selection) -> Void

    private let executor: AsyncProviderExecutor
    private let initialSearchTerm: String?
    private var currentSearchTerm: String?
    private var validSearchGeneration: Int?
    private var searchGeneration = 0
    private var searchTask: Task<Void, Never>?
    private var pendingSearchSubmission: Int?
    private var selectionTask: Task<Void, Never>?
    private var recentSearchTask: Task<Void, Never>?

    private var recentSearches: [String] {
        UserDefaults.standard[.recentSearches] ?? []
    }

    private lazy var resultViewController: SearchResultViewController = {
        return SearchResultViewController(selected: { [weak self] _, display, selection in
            guard let self else { return }
            self.selectResult(named: display, selection: selection)
        }, contentScrollViewChanged: { [weak self] scrollView in
            guard let self else { return }
            self.setContentScrollView(scrollView)
        })
    }()

    public init(executor: AsyncProviderExecutor, initialSearchTerm: String? = nil, selected: @escaping (_ viewController: SearchViewController, _ display: String, _ selection: Selection) -> Void) {
        self.selected = selected
        self.executor = executor
        self.initialSearchTerm = initialSearchTerm
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
        #if targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(self, selector: #selector(searchSceneDidActivate(_:)),
                                               name: UIScene.didActivateNotification, object: nil)
        #else
        if #available(iOS 26.0, *) {
            navigationItem.searchBarPlacementAllowsToolbarIntegration = false
        }
        #endif
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if targetEnvironment(macCatalyst)
        isSearchViewVisible = true
        activateToolbarSearchIfReady()
        #else
        guard shouldActivate else { return }
        pendingSearchFocus = true
        if isSearchPresented {
            focusSearchBarIfRequested()
        } else {
            searchController.isActive = true
        }
        #endif
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        selectionTask?.cancel()
        pendingSearchSubmission = nil
        #if targetEnvironment(macCatalyst)
        isSearchViewVisible = false
        #else
        pendingSearchFocus = false
        shouldActivate = searchController.searchBar.isFirstResponder
        #endif
    }

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
    #if !targetEnvironment(macCatalyst)
    func focusSearchBarIfRequested() {
        guard pendingSearchFocus else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.pendingSearchFocus, self.isSearchPresented,
                  self.searchController.isActive, self.viewIfLoaded?.window != nil else { return }
            if self.searchController.searchBar.becomeFirstResponder() {
                self.pendingSearchFocus = false
            } else {
                print("Could not focus search bar after presentation")
            }
        }
    }
    #endif

    func setUp() {
        title = CelestiaString("Search", comment: "")
        windowTitle = title

        install(resultViewController)
        showRecentSearches()

        #if !targetEnvironment(macCatalyst)
        // Configure search bar
        let searchBar = searchController.searchBar
        navigationItem.searchController = searchController

        searchBar.sizeToFit()

        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchBar.keyboardAppearance = .dark
        searchBar.delegate = self
        if let sheetCloseButtonItem {
            navigationItem.rightBarButtonItem = sheetCloseButtonItem
        }

        if let initialSearchTerm, !initialSearchTerm.isEmpty {
            searchBar.text = initialSearchTerm
            searchController.isActive = true
            searchTextUpdated(initialSearchTerm)
        }
        #else
        if let initialSearchTerm, !initialSearchTerm.isEmpty {
            searchTextUpdated(initialSearchTerm)
        }
        #endif
    }

    func searchTextUpdated(_ text: String?) {
        guard currentSearchTerm != text else {
            if text?.isEmpty != false {
                showRecentSearches()
            }
            return
        }

        currentSearchTerm = text
        selectionTask?.cancel()
        recentSearchTask?.cancel()
        searchGeneration &+= 1
        validSearchGeneration = nil
        pendingSearchSubmission = nil
        guard let text, !text.isEmpty else {
            fullMatch = Selection()
            showRecentSearches()
            return
        }

        resultViewController.updateSearchState(true)
        resultViewController.updateResults(resultSections: [])
        resultViewController.updateState(.loading)

        guard searchTask == nil else { return }
        searchTask = Task { [weak self] in
            guard let self else { return }
            defer {
                searchTask = nil
                if let text = currentSearchTerm,
                   pendingSearchSubmission == searchGeneration,
                   validSearchGeneration == searchGeneration {
                    itemSelected(with: text)
                }
            }

            while let text = currentSearchTerm, !text.isEmpty {
                let generation = searchGeneration
                do {
                    try await Task.sleep(nanoseconds: 200_000_000)
                } catch {
                    if !Task.isCancelled {
                        print("Search debounce failed: \(error)")
                    }
                    return
                }
                guard generation == searchGeneration else { continue }

                let (sections, fullMatch) = await search(with: text)
                guard generation == searchGeneration else { continue }
                validSearchGeneration = generation
                self.fullMatch = fullMatch
                resultViewController.updateResults(resultSections: sections)
                resultViewController.updateState(.results(empty: resultViewController.isEmpty))
                return
            }
        }
    }

    func searchTextReturned(_ text: String?) {
        guard let text, !text.isEmpty, resultViewController.isEmpty else { return }
        if currentSearchTerm != text {
            searchTextUpdated(text)
        }
        guard validSearchGeneration == searchGeneration else {
            pendingSearchSubmission = searchGeneration
            return
        }
        itemSelected(with: text)
    }

    private func itemSelected(with name: String) {
        selectResult(named: name, selection: fullMatch)
    }

    private func selectResult(named name: String, selection: Selection) {
        pendingSearchSubmission = nil
        selectionTask?.cancel()
        recentSearchTask?.cancel()
        selectionTask = Task { [weak self] in
            guard let self else { return }
            let path = await executor.get { core in
                core.simulation.universe.path(for: selection)
            }
            guard !Task.isCancelled else { return }
            if !selection.isEmpty, !path.isEmpty {
                UserDefaults.standard[.recentSearches] = Array(([path] + recentSearches.filter { $0 != path }).prefix(10))
            }
            #if !targetEnvironment(macCatalyst)
            searchController.searchBar.resignFirstResponder()
            #endif
            selected(self, name, selection)
        }
    }

    private func showRecentSearches() {
        recentSearchTask?.cancel()
        let paths = recentSearches
        resultViewController.updateResults(resultSections: [])
        resultViewController.updateSearchState(!paths.isEmpty)
        resultViewController.updateState(paths.isEmpty ? .empty : .loading)
        guard !paths.isEmpty else { return }
        recentSearchTask = Task { [weak self] in
            guard let self else { return }
            let results: [SearchResult] = await executor.get { core in
                paths.compactMap { path in
                    let selection = core.simulation.findObject(from: path)
                    guard !selection.isEmpty else { return nil }
                    return SearchResult(name: core.simulation.universe.name(for: selection), selection: selection)
                }
            }
            guard !Task.isCancelled else { return }
            resultViewController.updateResults(resultSections: results.isEmpty ? [] : [
                SearchResultSection(section: .recent, results: results),
            ])
            resultViewController.updateSearchState(!results.isEmpty)
            resultViewController.updateState(results.isEmpty ? .empty : .results(empty: false))
        }
    }
}

#if !targetEnvironment(macCatalyst)
extension SearchViewController: UISearchBarDelegate {
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActivationHandler?()
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchTextReturned(searchBar.text)
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if let cancelHandler {
            cancelHandler()
        } else {
            searchTextUpdated(nil)
        }
    }
}

extension SearchViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        searchTextUpdated(searchController.searchBar.text)
    }
}

extension SearchViewController: UISearchControllerDelegate {
    public func willPresentSearchController(_ searchController: UISearchController) {
        searchActivationHandler?()
        if sheetCloseButtonItem != nil {
            navigationItem.rightBarButtonItem = nil
        }
    }

    public func willDismissSearchController(_ searchController: UISearchController) {
        isSearchPresented = false
        pendingSearchFocus = false
        if let sheetCloseButtonItem {
            navigationItem.rightBarButtonItem = sheetCloseButtonItem
        }
    }

    public func didPresentSearchController(_ searchController: UISearchController) {
        isSearchPresented = true
        focusSearchBarIfRequested()
    }
}
#endif

extension SearchViewController {
    private func search(with text: String) async -> (results: [SearchResultSection], fullMatch: Selection) {
        let results: (completions: [SearchResult], fullMatch: Selection) = await executor.get { core in
            let completions = core.simulation.completion(for: text)
            let fullMatch = core.simulation.findObject(from: text)
            return (completions.map { SearchResult(name: $0.name, selection: $0.selection) }, fullMatch)
        }
        return ([SearchResultSection(section: .main, results: results.completions)], results.fullMatch)
    }
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: GoToInputViewController.self).bundleIdentifier!
    fileprivate static let search = NSToolbarItem.Identifier.init("\(prefix).search")
}

extension SearchViewController: ToolbarAwareViewController {
    @objc private func searchSceneDidActivate(_ notification: Notification) {
        guard let scene = notification.object as? UIWindowScene,
              scene === viewIfLoaded?.window?.windowScene else { return }
        activateToolbarSearchIfReady()
    }

    private func activateToolbarSearchIfReady() {
        guard shouldActivate, isSearchViewVisible,
              viewIfLoaded?.window?.windowScene?.activationState == .foregroundActive,
              let searchToolbarItem else { return }
        let selector = NSSelectorFromString("beginSearchInteraction")
        guard searchToolbarItem.responds(to: selector) else {
            print("Search toolbar item does not support search activation")
            shouldActivate = false
            return
        }
        typealias BeginSearchMethod = @convention(c) (NSObject, Selector) -> Void
        let method = unsafeBitCast(searchToolbarItem.method(for: selector), to: BeginSearchMethod.self)
        shouldActivate = false
        method(searchToolbarItem, selector)
    }

    public func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier] {
        return [.search]
    }

    public func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        if itemIdentifier == .search {
            let item = NSToolbarItem.searchItem(with: .search, currentText: currentSearchTerm) { [weak self] text in
                guard let self else { return }
                self.searchTextUpdated(text)
            } returnHandler: { [weak self] text in
                guard let self else { return }
                self.searchTextReturned(text)
            } searchStartHandler: { [weak self] in
                guard let self, self.currentSearchTerm?.isEmpty != false else { return }
                self.showRecentSearches()
            } searchEndHandler: {}
            searchToolbarItem = item
            return item
        }
        return nil
    }
}
#endif
