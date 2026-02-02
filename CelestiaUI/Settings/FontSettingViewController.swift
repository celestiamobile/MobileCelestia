// FontSettingViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

struct DisplayFont: Sendable, Hashable {
    let font: CustomFont
    let name: String
}

public struct CustomFont: Codable, Sendable, Hashable {
    public let path: String
    public let ttcIndex: Int

    public init(path: String, ttcIndex: Int) {
        self.path = path
        self.ttcIndex = ttcIndex
    }
}

final class FontSettingViewController: UICollectionViewController {
    private let userDefaults: UserDefaults
    private let normalFontPathKey: String
    private let normalFontIndexKey: String
    private let boldFontPathKey: String
    private let boldFontIndexKey: String
    private let customFonts: [DisplayFont]
    private var isBold = false

    private var normalFont: CustomFont?
    private var boldFont: CustomFont?

    enum Section {
        case `default`
        case custom
    }

    enum Item: Hashable {
        case `default`
        case custom(DisplayFont)
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [unowned self] cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.celestiaCell()
            var accessories: [UICellAccessory] = []
            let text: String
            let current = self.isBold ? self.boldFont : self.normalFont
            switch itemIdentifier {
            case .default:
                text = CelestiaString("Default", comment: "")
                if current == nil {
                    accessories = [.checkmark()]
                }
            case let .custom(font):
                text = font.name
                if current?.path == font.font.path && current?.ttcIndex == font.font.ttcIndex {
                    accessories = [.checkmark()]
                }
            }
            contentConfiguration.text = text
            cell.contentConfiguration = contentConfiguration
            cell.accessories = accessories
        }

        let footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) { supplementaryView, elementKind, indexPath in
            var contentConfiguration = UIListContentConfiguration.groupedFooter()
            contentConfiguration.text = CelestiaString("Configuration will take effect after a restart.", comment: "Change requires a restart")
            supplementaryView.contentConfiguration = contentConfiguration
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { [unowned self] supplementaryView, elementKind, indexPath in
            supplementaryView.contentConfiguration = SegmentedControlConfiguration(segmentTitles: [
                CelestiaString("Normal", comment: "Normal font style"),
                CelestiaString("Bold", comment: "Bold font style")
            ], selectedSegmentIndex: self.isBold ? 1 : 0, selectedIndexChanged: { [weak self] index in
                guard let self else { return }
                self.isBold = index == 1
                self.reload()
            })
        }

        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self else { return nil }
            let section = self.dataSource.sectionIdentifier(for: indexPath.section)
            if section == .custom, kind == UICollectionView.elementKindSectionFooter {
                return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration, for: indexPath)
            }
            if section == .default, kind == UICollectionView.elementKindSectionHeader {
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            }
            return nil
        }

        return dataSource
    }()

    init(userDefaults: UserDefaults, normalFontPathKey: String, normalFontIndexKey: String, boldFontPathKey: String, boldFontIndexKey: String, customFonts: [DisplayFont]) {
        self.userDefaults = userDefaults
        self.normalFontPathKey = normalFontPathKey
        self.normalFontIndexKey = normalFontIndexKey
        self.boldFontPathKey = boldFontPathKey
        self.boldFontIndexKey = boldFontIndexKey
        self.customFonts = customFonts

        super.init(collectionViewLayout: UICollectionViewFlowLayout())

        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            var listConfiguration = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
            if let self {
                switch dataSource.sectionIdentifier(for: sectionIndex) {
                case .default:
                    listConfiguration.headerMode = .supplementary
                case .custom:
                    listConfiguration.footerMode = .supplementary
                case nil:
                    break
                }
            }
            return NSCollectionLayoutSection.list(using: listConfiguration, layoutEnvironment: layoutEnvironment)
        }

        if let normalFontPath = userDefaults.string(forKey: normalFontPathKey) {
            let normalFontIndex = userDefaults.integer(forKey: normalFontIndexKey)
            normalFont = CustomFont(path: normalFontPath, ttcIndex: normalFontIndex)
        }
        if let boldFontPath = userDefaults.string(forKey: boldFontPathKey) {
            let boldFontIndex = userDefaults.integer(forKey: boldFontIndexKey)
            boldFont = CustomFont(path: boldFontPath, ttcIndex: boldFontIndex)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = CelestiaString("Font", comment: "")
        windowTitle = navigationItem.title

        collectionView.dataSource = self
        reload()
    }

    private func reload() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.default, .custom])
        snapshot.appendItems([.default], toSection: .default)
        snapshot.appendItems(customFonts.map { .custom($0) }, toSection: .custom)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

extension FontSettingViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        let customFont: DisplayFont?
        switch item {
        case let .custom(font):
            customFont = font
        case .default:
            customFont = nil
        }

        if isBold {
            boldFont = customFont?.font
            userDefaults.setValue(customFont?.font.path, forKey: boldFontPathKey)
            userDefaults.setValue(customFont?.font.ttcIndex, forKey: boldFontIndexKey)
        } else {
            normalFont = customFont?.font
            userDefaults.setValue(customFont?.font.path, forKey: normalFontPathKey)
            userDefaults.setValue(customFont?.font.ttcIndex, forKey: normalFontIndexKey)
        }

        reload()
    }
}
