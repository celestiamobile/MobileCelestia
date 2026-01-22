// DataLocationSelectionViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaFoundation
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

class DataLocationSelectionViewController: UICollectionViewController {
    private enum Section: Hashable {
        case locations
        case actions
    }

    private enum Item: Hashable {
        case dataDirectory
        case configFile
        case reset
    }

    private let userDefaults: UserDefaults
    private let dataDirectoryUserDefaultsKey: String
    private let configFileUserDefaultsKey: String
    private let defaultDataDirectoryURL: URL
    private let defaultConfigFileURL: URL

    private enum Location: Int {
        case dataDirectory
        case configFile
    }

    private var currentPicker: Location?

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            let text: String
            var secondaryText: String?
            var accessories: [UICellAccessory] = []
            
            switch itemIdentifier {
            case .dataDirectory:
                text = CelestiaString("Data Directory", comment: "Directory to load data from")
                if let self {
                    secondaryText = self.userDefaults.url(for: self.dataDirectoryUserDefaultsKey, defaultValue: self.defaultDataDirectoryURL).url == self.defaultDataDirectoryURL ? CelestiaString("Default", comment: "") : CelestiaString("Custom", comment: "")
                }
                accessories = [.disclosureIndicator()]
            case .configFile:
                text = CelestiaString("Config File", comment: "celestia.cfg")
                if let self {
                    secondaryText = self.userDefaults.url(for: self.configFileUserDefaultsKey, defaultValue: self.defaultConfigFileURL).url == self.defaultConfigFileURL ? CelestiaString("Default", comment: "") : CelestiaString("Custom", comment: "")
                }
                accessories = [.disclosureIndicator()]
            case .reset:
                text = CelestiaString("Reset to Default", comment: "Reset celestia.cfg, data directory location")
                secondaryText = nil
            }
            
            contentConfiguration.text = text
            contentConfiguration.secondaryText = secondaryText
            if itemIdentifier == .reset {
                contentConfiguration.textProperties.color = cell.tintColor
            }
            contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: GlobalConstants.listItemMediumMarginVertical, leading: GlobalConstants.listItemMediumMarginHorizontal, bottom: GlobalConstants.listItemMediumMarginVertical, trailing: GlobalConstants.listItemMediumMarginHorizontal)
            cell.contentConfiguration = contentConfiguration
            cell.accessories = accessories
        }
        
        let footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) { supplementaryView, elementKind, indexPath in
            var contentConfiguration = UIListContentConfiguration.groupedFooter()
            contentConfiguration.text = CelestiaString("Configuration will take effect after a restart.", comment: "Change requires a restart")
            supplementaryView.contentConfiguration = contentConfiguration
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self, kind == UICollectionView.elementKindSectionFooter else { return nil }
            let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            if section == .locations {
                return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration, for: indexPath)
            }
            return nil
        }
        
        return dataSource
    }()

    init(userDefaults: UserDefaults, dataDirectoryUserDefaultsKey: String, configFileUserDefaultsKey: String, defaultDataDirectoryURL: URL, defaultConfigFileURL: URL) {
        self.userDefaults = userDefaults
        self.dataDirectoryUserDefaultsKey = dataDirectoryUserDefaultsKey
        self.configFileUserDefaultsKey = configFileUserDefaultsKey
        self.defaultConfigFileURL = defaultConfigFileURL
        self.defaultDataDirectoryURL = defaultDataDirectoryURL
        
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var listConfiguration = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
            if sectionIndex == 0 { // .locations section
                listConfiguration.footerMode = .supplementary
            }
            return NSCollectionLayoutSection.list(using: listConfiguration, layoutEnvironment: layoutEnvironment)
        }
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadContents()
    }

    private func loadContents() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.locations, .actions])
        snapshot.appendItems([.dataDirectory, .configFile], toSection: .locations)
        snapshot.appendItems([.reset], toSection: .actions)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

private extension DataLocationSelectionViewController {
    func setUp() {
        title = CelestiaString("Data Location", comment: "Title for celestia.cfg, data location setting")
        windowTitle = title
    }
}

extension DataLocationSelectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .reset:
            userDefaults.setValue(nil, forKey: dataDirectoryUserDefaultsKey)
            userDefaults.setValue(nil, forKey: configFileUserDefaultsKey)
            loadContents()
        case .dataDirectory, .configFile:
            let types = [UTType.folder, UTType.data]
            let typeIndex = item == .dataDirectory ? 0 : 1
            let browser = UIDocumentPickerViewController(forOpeningContentTypes: [types[typeIndex]])
            currentPicker = Location(rawValue: typeIndex)
            browser.allowsMultipleSelection = false
            browser.delegate = self
            present(browser, animated: true, completion: nil)
        }
    }
}

extension DataLocationSelectionViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        // try to start reading
        if !url.startAccessingSecurityScopedResource() {
            showError(CelestiaString("Operation not permitted.", comment: ""))
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // save the bookmark for next launch
        do {
            #if targetEnvironment(macCatalyst)
            let bookmark = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
            #else
            let bookmark = try url.bookmarkData(options: .init(rawValue: 0), includingResourceValuesForKeys: nil, relativeTo: nil)
            #endif
            if currentPicker == .dataDirectory {
                userDefaults.setValue(bookmark, forKey: dataDirectoryUserDefaultsKey)
            } else if currentPicker == .configFile {
                userDefaults.setValue(bookmark, forKey: configFileUserDefaultsKey)
            }
        } catch let error {
            showError(error.localizedDescription)
        }
        loadContents()

        // FIXME: should ask for a relaunch
    }
}
