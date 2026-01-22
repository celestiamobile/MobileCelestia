// SettingsFrameRateViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#if !os(visionOS)
import UIKit

class SettingsFrameRateViewController: UICollectionViewController {
    public enum FrameRate: Hashable {
        case fixed(Int)
        case maximum
    }

    public enum Section {
        case single
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, FrameRate> = {
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.usesGroupingSeparator = true
            return formatter
        }()
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, FrameRate> { [unowned self] cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.celestiaCell()
            let selectedFrameRate: Int = self.userDefaults.value(forKey: self.userDefaultsKey) as? Int ?? 60
            let text: String
            let accessories: [UICellAccessory]
            switch itemIdentifier {
            case let .fixed(value):
                text = String.localizedStringWithFormat(CelestiaString("%@ FPS", comment: ""), numberFormatter.string(from: value))
                accessories = value == selectedFrameRate ? [.checkmark()] : []
            case .maximum:
                if let screen = self.screen {
                    text = String.localizedStringWithFormat(CelestiaString("Maximum (%@ FPS)", comment: ""), numberFormatter.string(from: screen.maximumFramesPerSecond))
                    accessories = -1 == selectedFrameRate ? [.checkmark()] : []
                } else {
                    text = ""
                    accessories = []
                }
            }
            contentConfiguration.text = text
            cell.contentConfiguration = contentConfiguration
            cell.accessories = accessories
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, FrameRate>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        return dataSource
    }()

    private let userDefaults: UserDefaults
    private let userDefaultsKey: String

    private let frameRateUpdateHandler: (Int) -> Void
    private let screen: UIScreen?

    init(screen: UIScreen?, userDefaults: UserDefaults, userDefaultsKey: String, frameRateUpdateHandler: @escaping (Int) -> Void) {
        self.screen = screen
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey
        self.frameRateUpdateHandler = frameRateUpdateHandler
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .defaultGrouped)))
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
        let maxFrameRate = screen?.maximumFramesPerSecond

        var snapshot = NSDiffableDataSourceSnapshot<Section, FrameRate>()
        snapshot.appendSections([.single])
        for fixedFrameRate in [60, 30, 20] {
            if let maxFrameRate, fixedFrameRate > maxFrameRate {
                continue
            }
            snapshot.appendItems([.fixed(fixedFrameRate)], toSection: .single)
        }

        if maxFrameRate != nil {
            snapshot.appendItems([.maximum], toSection: .single)
        }
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

private extension SettingsFrameRateViewController {
    func setUp() {
        title = CelestiaString("Frame Rate", comment: "Frame rate of simulation")
        windowTitle = title

        collectionView.dataSource = dataSource
    }
}

extension SettingsFrameRateViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case let .fixed(value):
            frameRateUpdateHandler(value)
        case .maximum:
            frameRateUpdateHandler(-1)
        }
        loadContents()
    }
}
#endif
