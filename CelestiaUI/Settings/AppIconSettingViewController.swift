//
// AppIconSettingViewController.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

#if !os(visionOS) && !targetEnvironment(macCatalyst)
class AppIconSettingViewController: SubscriptionBackingViewController {
    private class ContentViewController: UICollectionViewController {
        private let assetProvider: AssetProvider

        private enum Section {
            case single
        }

        private enum AlternateIconName: Hashable {
            case classic

            var iconName: String {
                switch self {
                case .classic:
                    return "Classic"
                }
            }

            var preview: AssetImage {
                switch self {
                case .classic:
                    return .classicIcon
                }
            }

            var displayName: String {
                switch self {
                case .classic:
                    return CelestiaString("Classic", comment: "Display name for classic icon")
                }
            }
        }

        private enum IconName: Hashable {
            case `default`
            case alternate(AlternateIconName)

            var preview: AssetImage {
                switch self {
                case .default:
                    return .defaultIcon
                case .alternate(let alternateIconName):
                    return alternateIconName.preview
                }
            }

            var displayName: String {
                switch self {
                case .default:
                    return CelestiaString("Default", context: "Icon", comment: "Display name for default icon")
                case .alternate(let alternateIconName):
                    return alternateIconName.displayName
                }
            }

            var iconName: String? {
                switch self {
                case .default:
                    return nil
                case .alternate(let alternateIconName):
                    return alternateIconName.iconName
                }
            }
        }

        private enum Item: Hashable {
            case icon(IconName)
        }

        private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
            let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] cell, indexPath, itemIdentifier in
                var contentConfiguration = UIListContentConfiguration.celestiaCell()
                let accessories: [UICellAccessory]
                switch itemIdentifier {
                case let .icon(name):
                    contentConfiguration.text = name.displayName
                    if let self {
                        contentConfiguration.image = self.assetProvider.image(for: name.preview)
                    }
                    accessories = UIApplication.shared.alternateIconName == name.iconName ? [.checkmark(displayed: .always)] : []
                }
                cell.contentConfiguration = contentConfiguration
                cell.accessories = accessories
            }
            let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
            return dataSource
        }()

        init(assetProvider: AssetProvider) {
            self.assetProvider = assetProvider

            super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .defaultGrouped)))
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            navigationItem.title = CelestiaString("App Icon", comment: "App icon customization entry in Settings")
            windowTitle = navigationItem.title

            reload()
        }

        private func reload() {
            var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
            snapshot.appendSections([.single])
            snapshot.appendItems([.icon(.default), .icon(.alternate(.classic))], toSection: .single)
            dataSource.applySnapshotUsingReloadData(snapshot)
        }

        override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            collectionView.deselectItem(at: indexPath, animated: true)
            guard let item = dataSource.itemIdentifier(for: indexPath) else { return }


            switch item {
            case let .icon(name):
                let app = UIApplication.shared
                guard app.alternateIconName != name.iconName else { return }
                app.setAlternateIconName(name.iconName, completionHandler: { [weak self] _ in
                    Task { @MainActor in
                        guard let self else { return }
                        self.reload()
                    }
                })
            }
        }
    }

    init(subscriptionManager: SubscriptionManager, assetProvider: AssetProvider, openSubscriptionManagement: @escaping () -> Void) {
        super.init(subscriptionManager: subscriptionManager, openSubscriptionManagement: openSubscriptionManagement) { containerViewController in
            return ContentViewController(assetProvider: assetProvider)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureEmptyNavigationBar() {
        super.configureEmptyNavigationBar()

        navigationItem.title = CelestiaString("App Icon", comment: "App icon customization entry in Settings")
        windowTitle = navigationItem.title
    }
}
#endif
