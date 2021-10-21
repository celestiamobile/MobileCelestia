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

class SearchViewController: UIViewController {
    private lazy var searchController = UISearchController(searchResultsController: resultController)

    private let resultsInSidebar: Bool

    private lazy var resultController = SearchResultViewController(inSidebar: resultsInSidebar) { [weak self] name in
        self?.itemSelected(with: name)
    }

    private var searchQueue = OperationQueue()

    private var resultSections: [SearchResultSection] = []

    private let selected: (String) -> Void

    private var shouldActivate = true

    init(resultsInSidebar: Bool, selected: @escaping (String) -> Void) {
        self.resultsInSidebar = resultsInSidebar
        self.selected = selected
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()

        if #available(iOS 13, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            navigationItem.standardAppearance = appearance
            navigationItem.compactAppearance = appearance
            navigationItem.scrollEdgeAppearance = appearance
            if #available(iOS 15, *) {
                navigationItem.compactScrollEdgeAppearance = appearance
            }
        }

        #if !targetEnvironment(macCatalyst)
        view.backgroundColor = .darkBackground
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if shouldActivate {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                _ = self?.searchController.searchBar.becomeFirstResponder()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)

        shouldActivate = searchController.searchBar.isFirstResponder
    }

    deinit {
        searchQueue.cancelAllOperations()
    }
}

private extension SearchViewController {
    func setUp() {
        searchQueue.maxConcurrentOperationCount = 1

        // Configure search bar
        let searchBar = searchController.searchBar
        searchBar.searchBarStyle = .minimal
        navigationItem.titleView = searchBar

        if #available(iOS 13.0, *) {
        } else {
            if searchBar.responds(to: NSSelectorFromString("searchField")) {
                if let textField = searchBar.value(forKey: "searchField") as? UITextField {
                    textField.textColor = .darkLabel
                }
            }
        }

        searchBar.sizeToFit()

        definesPresentationContext = true
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchBar.keyboardAppearance = .dark
        searchBar.delegate = self
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
            resultController.update([])
            return
        }

        searchQueue.cancelAllOperations()
        searchQueue.addOperation { [weak self] in
            guard let self = self else { return }
            let results = self.search(with: text)
            DispatchQueue.main.async {
                guard text == self.searchController.searchBar.text else { return }
                self.resultController.update(results)
            }
        }
    }
}

extension SearchViewController {
    private func search(with text: String) -> [SearchResultSection] {
        let simulation = CelestiaAppCore.shared.simulation
        return [SearchResultSection(title: nil, results: simulation.completion(for: text).map { SearchResult(name: $0) })]
    }
}
