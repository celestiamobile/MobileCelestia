//
// SearchResultViewController.swift
//
// Copyright (C) 2025-present, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

struct SearchResult: Hashable {
    var id: Int { completion.hashValue }

    let completion: Completion
}

enum SearchSection: Hashable {
    var id: Self { self }
    case main
}

struct SearchResultSection {
    let section: SearchSection
    let results: [SearchResult]
}

public class SearchResultViewController: UIViewController {
    private var resultSections: [SearchResultSection] = []
    private var rawResults: [Completion] = []

    private let selected: (_ viewController: SearchResultViewController, _ display: String, _ selection: Selection) -> Void
    private let contentScrollViewChanged: (UIScrollView?) -> Void

    private lazy var emptyView = EmptyHintView()
    private lazy var loadingView = UIActivityIndicatorView(style: .large)
    private lazy var emptyViewContainer = SafeAreaView(view: emptyView)
    private lazy var loadingViewContainer = SafeAreaView(view: loadingView)

    private var contentViewController: SearchContentViewController?
    private var contentScrollView: UIScrollView?

    private lazy var resultViewController: UICollectionViewController = {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        return UICollectionViewController(collectionViewLayout: layout)
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<SearchSection, SearchResult> = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SearchResult> { cell, _, itemIdentifier in
            var configuration = UIListContentConfiguration.celestiaCell()
            configuration.text = itemIdentifier.completion.name
            cell.contentConfiguration = configuration
        }
        let dataSource = UICollectionViewDiffableDataSource<SearchSection, SearchResult>(collectionView: collectionView) { [weak self] collectionView, indexPath, itemIdentifier in
            guard let self else { fatalError() }
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] supplementaryView, _, indexPath in
            guard let self else { fatalError() }
            var configuration: UIListContentConfiguration
            if #available(iOS 18.0, visionOS 2.0, *) {
                configuration = UIListContentConfiguration.header()
            } else {
                configuration = UIListContentConfiguration.groupedHeader()
            }
            switch self.dataSource.sectionIdentifier(for: indexPath.section) {
            case .main:
                configuration.text = nil
            case nil:
                configuration.text = nil
            }
            supplementaryView.contentConfiguration = configuration
        }
        dataSource.supplementaryViewProvider = { [unowned self] collectionView, _, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }()

    private var collectionView: UICollectionView {
        return resultViewController.collectionView
    }

    enum State: Hashable {
        case empty
        case loading
        case results(empty: Bool)
    }

    private var state: State = .empty
    private var isSearchActive: Bool = false
    var isEmpty: Bool {
        return resultSections.reduce(0, { $0 + $1.results.count }) == 0
    }

    public init(selected: @escaping (_ viewController: SearchResultViewController, _ display: String, _ selection: Selection) -> Void, contentScrollViewChanged: @escaping (UIScrollView?) -> Void) {
        self.selected = selected
        self.contentScrollViewChanged = contentScrollViewChanged
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    public override var minimumSheetHeight: CGFloat {
        return contentViewController?.minimumSheetHeight ?? resultViewController.minimumSheetHeight
    }

    @available(iOS 17, visionOS 1, *)
    public override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
        var config: UIContentUnavailableConfiguration?
        switch self.state {
        case .empty:
            var empty = UIContentUnavailableConfiguration.empty()
            empty.text = CelestiaString("Find stars, DSOs, and nearby objects", comment: "")
            config = empty
        case .loading:
            config = UIContentUnavailableConfiguration.loading()
        case .results(let empty):
            if empty {
                var empty = UIContentUnavailableConfiguration.search()
                empty.text = CelestiaString("No result found", comment: "")
                config = empty
            }
        }

        if contentViewController != nil, !isSearchActive {
            config = nil
        }
        contentUnavailableConfiguration = config
    }

    func updateState(_ newState: State) {
        guard newState != state else { return }
        state = newState

        reload()
    }

    func updateSearchState(_ isActive: Bool) {
        guard isActive != isSearchActive else { return }
        isSearchActive = isActive

        reload()
    }

    func updateResults(resultSections: [SearchResultSection], rawResults: [Completion]) {
        self.resultSections = resultSections
        self.rawResults = rawResults

        var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchResult>()
        for resultSection in resultSections {
            snapshot.appendSections([resultSection.section])
            snapshot.appendItems(resultSection.results, toSection: resultSection.section)
        }
        dataSource.apply(snapshot)
    }

    private func updateContentScrollView(_ newContentScrollView: UIScrollView?) {
        setContentScrollView(newContentScrollView)
        if contentScrollView != newContentScrollView {
            contentScrollView = newContentScrollView
            contentScrollViewChanged(newContentScrollView)
        }
    }

    private func reload() {
        defer {
            if #available(iOS 17, visionOS 1, *) {
                setNeedsUpdateContentUnavailableConfiguration()
            }
        }

        if let contentViewController {
            if !isSearchActive {
                updateContentScrollView(contentViewController.contentScrollView)
                if #available(iOS 17, visionOS 1, *) {
                } else {
                    loadingView.stopAnimating()
                    emptyViewContainer.isHidden = true
                    loadingViewContainer.isHidden = true
                }
                resultViewController.view.isHidden = true
                contentViewController.view.isHidden = false
                view.sendSubviewToBack(contentViewController.view)
                return
            } else {
                contentViewController.view.isHidden = true
            }
        }

        switch state {
        case .empty:
            updateContentScrollView(nil)
            resultViewController.view.isHidden = true
            if #available(iOS 17, visionOS 1, *) {
            } else {
                loadingView.stopAnimating()
                loadingViewContainer.isHidden = true
                emptyView.title = CelestiaString("Find stars, DSOs, and nearby objects", comment: "")
                emptyViewContainer.isHidden = false
            }
        case .loading:
            updateContentScrollView(nil)
            resultViewController.view.isHidden = true
            if #available(iOS 17, visionOS 1, *) {
            } else {
                emptyViewContainer.isHidden = true
                loadingViewContainer.isHidden = false
                loadingView.startAnimating()
            }
        case .results(let empty):
            updateContentScrollView(resultViewController.collectionView)
            resultViewController.view.isHidden = empty
            if #available(iOS 17, visionOS 1, *) {
            } else {
                emptyView.title = empty ? CelestiaString("No result found", comment: "") : nil
                emptyViewContainer.isHidden = !empty
                loadingView.stopAnimating()
                loadingViewContainer.isHidden = true
            }
        }
    }

    func installContentViewController(_ viewController: SearchContentViewController) {
        if let contentViewController {
            contentViewController.remove()
            self.contentViewController = nil
        }

        install(viewController)
        contentViewController = viewController

        isSearchActive = false

        reload()
    }
}

private extension SearchResultViewController {
    func setUp() {
        install(resultViewController)

        if #available(iOS 17, visionOS 1, *) {
        } else {
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
        }

        #if !os(visionOS) && !targetEnvironment(macCatalyst)
        collectionView.keyboardDismissMode = .interactive
        #endif

        collectionView.dataSource = dataSource
        collectionView.delegate = self

        reload()
    }
}

extension SearchResultViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        selected(self, item.completion.name, item.completion.selection)
    }
}
