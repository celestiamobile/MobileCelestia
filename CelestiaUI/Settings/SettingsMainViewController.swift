//
// SettingsMainViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class SettingsMainViewController: UICollectionViewController {
    private let sections: [SettingSection]
    private let selection: (SettingItem) async -> Void

    init(sections: [SettingSection], selection: @escaping (SettingItem) async -> Void) {
        self.sections = sections
        self.selection = selection
        #if targetEnvironment(macCatalyst)
        var configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
        #else
        var configuration = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
        #endif
        configuration.headerMode = .supplementary

        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: configuration))
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
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "Text")
        collectionView.register(UICollectionViewListCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        title = CelestiaString("Settings", comment: "")
        windowTitle = title
    }
}

extension SettingsMainViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewListCell {
        let item = sections[indexPath.section].items[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Text", for: indexPath) as! UICollectionViewListCell
        #if targetEnvironment(macCatalyst)
        var configuration = UIListContentConfiguration.sidebarCell()
        #else
        var configuration = UIListContentConfiguration.celestiaCell()
        cell.accessories = [.disclosureIndicator()]
        #endif
        configuration.text = item.name
        cell.contentConfiguration = configuration
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! UICollectionViewListCell
        var configuration = UIListContentConfiguration.groupedHeader()
        configuration.text = sections[indexPath.section].title
        view.contentConfiguration = configuration
        return view
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Task {
            await selection(sections[indexPath.section].items[indexPath.item])
        }
    }
}
