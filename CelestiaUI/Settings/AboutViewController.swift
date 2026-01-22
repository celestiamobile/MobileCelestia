// AboutViewController.swift
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

public final class AboutViewController: UICollectionViewController {
    private let officialWebsiteURL = URL(string: "https://celestia.mobi")!
    private let aboutCelestiaURL = URL(string: "https://celestia.mobi/about")!

    private let bundle: Bundle
    private let defaultDirectoryURL: URL

    enum Section {
        case version
        case authors
        case translators
        case links1
        case links2
    }

    enum Item {
        case version
        case authors
        case translators
        case development
        case dependencies
        case privacyPolicy
        case website
        case about
    }

    private var authorText: String?
    private var translatorText: String?

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let cellRegistration = UICollectionView.CellRegistration<SelectableListCell, Item> { [unowned self] cell, indexPath, itemIdentifier in
            let text: String
            var secondaryText: String?
            var useValueCell = false
            var tinted = false
            var selectable = true
            switch itemIdentifier {
            case .version:
                text = CelestiaString("Version", comment: "")
                secondaryText = "\(self.bundle.shortVersion)(\(self.bundle.build))"
                useValueCell = true
                selectable = false
            case .authors:
                text = CelestiaString("Authors", comment: "Authors for Celestia")
                secondaryText = self.authorText
                selectable = false
            case .translators:
                text = CelestiaString("Translators", comment: "Translators for Celestia")
                secondaryText = self.translatorText
                selectable = false
            case .development:
                text = CelestiaString("Development", comment: "URL for Development wiki")
                tinted = true
            case .dependencies:
                text = CelestiaString("Third Party Dependencies", comment: "URL for Third Party Dependencies wiki")
                tinted = true
            case .privacyPolicy:
                text = CelestiaString("Privacy Policy and Service Agreement", comment: "Privacy Policy and Service Agreement")
                tinted = true
            case .website:
                text = CelestiaString("Official Website", comment: "")
                tinted = true
            case .about:
                text = CelestiaString("About Celestia", comment: "System menu item")
                tinted = true
            }
            var contentConfiguration = useValueCell ? UIListContentConfiguration.celestiaValueCell() : UIListContentConfiguration.celestiaCell()
            if tinted {
                contentConfiguration.textProperties.color = cell.tintColor
            }
            contentConfiguration.text = text
            contentConfiguration.secondaryText = secondaryText
            cell.contentConfiguration = contentConfiguration
            cell.selectable = selectable
        }

        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        #if !targetEnvironment(macCatalyst)
        let footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) { supplementaryView, _, _ in
            supplementaryView.contentConfiguration = ICPCConfiguration(text: "苏ICP备2023039249号-4A")
        }
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self, kind == UICollectionView.elementKindSectionFooter else { return nil }
            let section = self.dataSource.sectionIdentifier(for: indexPath.section)
            if section == .links2 {
                return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration, for: indexPath)
            }
            return nil
        }
        #endif
        return dataSource
    }()

    public init(bundle: Bundle, defaultDirectoryURL: URL) {
        self.bundle = bundle
        self.defaultDirectoryURL = defaultDirectoryURL

        #if targetEnvironment(macCatalyst)
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .defaultGrouped)))
        #else
        let showFooter: Bool
        if #available(iOS 16, visionOS 1, *) {
            showFooter = Locale.current.region == .chinaMainland
        } else {
            showFooter = Locale.current.regionCode == "CN"
        }
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            var listConfiguration = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
            if let self, showFooter, self.dataSource.sectionIdentifier(for: sectionIndex) == .links2 {
                listConfiguration.footerMode = .supplementary
            }
            return NSCollectionLayoutSection.list(using: listConfiguration, layoutEnvironment: layoutEnvironment)
        }
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
        loadContents()
    }

    private func loadContents() {
        let authorsPath = defaultDirectoryURL.appendingPathComponent("AUTHORS").path
        if let text = try? String(contentsOfFile: authorsPath) {
            authorText = text
        }

        let translatorsPath = defaultDirectoryURL.appendingPathComponent("TRANSLATORS").path
        if let text = try? String(contentsOfFile: translatorsPath) {
            translatorText = text
        }

        collectionView.dataSource = dataSource

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.version])
        snapshot.appendItems([.version], toSection: .version)
        if authorText != nil {
            snapshot.appendSections([.authors])
            snapshot.appendItems([.authors], toSection: .authors)
        }
        if translatorText != nil {
            snapshot.appendSections([.translators])
            snapshot.appendItems([.translators], toSection: .translators)
        }
        snapshot.appendSections([.links1, .links2])
        snapshot.appendItems([.development, .dependencies, .privacyPolicy], toSection: .links1)
        snapshot.appendItems([.website, .about], toSection: .links2)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

private extension AboutViewController {
    func setUp() {
        title = CelestiaString("About", comment: "About Celestia")
        windowTitle = title

        collectionView.dataSource = dataSource
    }
}

extension AboutViewController {
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        let url: URL
        let localizable: Bool
        switch item {
        case .version, .authors, .translators:
            return
        case .development:
            url = URL(string: "https://celestia.mobi/help/development")!
            localizable = false
        case .dependencies:
            url = URL(string: "https://celestia.mobi/help/dependencies")!
            localizable = true
        case .privacyPolicy:
            url = URL(string: "https://celestia.mobi/privacy")!
            localizable = true
        case .website:
            url = officialWebsiteURL
            localizable = true
        case .about:
            url = aboutCelestiaURL
            localizable = true
        }

        let urlToOpen: URL
        if localizable {
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                var queryItems = components.queryItems ?? []
                queryItems.append(URLQueryItem(name: "lang", value: AppCore.language))
                components.queryItems = queryItems
                urlToOpen = components.url ?? url
            } else {
                urlToOpen = url
            }
        } else {
            urlToOpen = url
        }
        UIApplication.shared.open(urlToOpen)
    }
}
