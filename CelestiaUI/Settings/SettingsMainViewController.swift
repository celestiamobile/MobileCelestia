// SettingsMainViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

class SettingsMainViewController: UICollectionViewController {
    private let sections: [SettingSection]
    private let selection: (SettingItem) async -> Void

    init(sections: [SettingSection], selection: @escaping (SettingItem) async -> Void) {
        self.sections = sections
        self.selection = selection
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            #if targetEnvironment(macCatalyst)
            var configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
            #else
            var configuration = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
            #endif
            configuration.headerMode = sections[sectionIndex].title == nil ? .none : .supplementary
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension SettingsMainViewController {
    func setUp() {
        title = CelestiaString("Settings", comment: "")
        windowTitle = title

        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "Text")
        collectionView.register(UICollectionViewListCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
    }
}

extension SettingsMainViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Text", for: indexPath) as! UICollectionViewListCell
        let item = sections[indexPath.section].items[indexPath.row]
        #if targetEnvironment(macCatalyst)
        var configuration = UIListContentConfiguration.sidebarCell()
        configuration.text = item.name
        #else
        cell.accessories = [.disclosureIndicator()]
        var configuration = UIListContentConfiguration.celestiaCell()
        #endif
        configuration.text = item.name
        cell.contentConfiguration = configuration
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! UICollectionViewListCell
        #if targetEnvironment(macCatalyst)
        var configuration = UIListContentConfiguration.sidebarHeader()
        #else
        var configuration = UIListContentConfiguration.groupedHeader()
        #endif
        configuration.text = sections[indexPath.section].title

        header.contentConfiguration = configuration
        return header
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Task {
            await selection(sections[indexPath.section].items[indexPath.row])
        }
    }
}
