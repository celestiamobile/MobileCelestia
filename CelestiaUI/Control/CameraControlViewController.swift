// CameraControlViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Combine
import CelestiaCore
import UIKit

#if os(iOS) && !targetEnvironment(macCatalyst)
public class GyroscopeSettings: ObservableObject {
    @Published public var isEnabled: Bool

    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}
#endif

public final class CameraControlViewController: UICollectionViewController {
    private struct KeyAction {
        let title: String
        let minusKey: Int
        let plusKey: Int
    }

    private enum PitchYawRollZoom {
        case pitch
        case yaw
        case roll
        case zoom

        var plusKey: Int {
            switch self {
            case .pitch:
                26
            case .yaw:
                30
            case .roll:
                33
            case .zoom:
                5
            }
        }

        var minusKey: Int {
            switch self {
            case .pitch:
                32
            case .yaw:
                28
            case .roll:
                31
            case .zoom:
                6
            }
        }
    }

    private enum Section {
        case pitchYawRow
        case zoom
        case flightMode
        case reverseOrientation
        #if os(iOS) && !targetEnvironment(macCatalyst)
        case gyroscope
        #endif
    }

    private enum Item: Hashable {
        case pitchYawRollZoom(PitchYawRollZoom)
        case flightMode
        case reverseOrientation
        #if os(iOS) && !targetEnvironment(macCatalyst)
        case gyroscope
        #endif
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let cellRegistration = UICollectionView.CellRegistration<SelectableListCell, Item> { [unowned self] cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.celestiaCell()
            let text: String
            var accessories: [UICellAccessory] = []
            var selectable = false
            switch itemIdentifier {
            case let .pitchYawRollZoom(pyrz):
                let stepperView = StepperView()
                switch pyrz {
                case .pitch:
                    text = CelestiaString("Pitch", comment: "Camera control")
                case .yaw:
                    text = CelestiaString("Yaw", comment: "Camera control")
                case .roll:
                    text = CelestiaString("Roll", comment: "Camera control")
                case .zoom:
                    text = CelestiaString("Zoom (Distance)", comment: "Zoom in/out in Camera Control, this changes the relative distance to the object")
                }
                stepperView.changeBlock = { [weak self] plus in
                    guard let self else { return }
                    self.handleKeyAction(pyrz, plus: plus)
                }
                stepperView.stopBlock = { [weak self] in
                    guard let self else { return }
                    self.handleStop()
                }
                accessories = [.customView(configuration: UICellAccessory.CustomViewConfiguration(customView: stepperView, placement: .trailing(displayed: .always), reservedLayoutWidth: .actual))]
            case .flightMode:
                text = CelestiaString("Flight Mode", comment: "")
                selectable = true
                accessories = [.disclosureIndicator()]
            case .reverseOrientation:
                text = CelestiaString("Reverse Direction", comment: "Reverse camera direction, reverse travel direction")
                selectable = true
            #if os(iOS) && !targetEnvironment(macCatalyst)
            case .gyroscope:
                text = CelestiaString("Enable Gyroscope Control", comment: "Enable gyroscope control for camera rotation")
                let toggle = UISwitch()
                toggle.addTarget(self, action: #selector(self.gyroscopeSettingsChanged(_:)), for: .valueChanged)
                toggle.isOn = self.gyroscopeSettings.isEnabled
                accessories = [.customView(configuration: UICellAccessory.CustomViewConfiguration(customView: toggle, placement: .trailing(displayed: .always)))]
            #endif
            }
            contentConfiguration.text = text
            cell.contentConfiguration = contentConfiguration
            cell.selectable = selectable
            cell.accessories = accessories
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        let footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) { [weak self] supplementaryView, elementKind, indexPath in
            var contentConfiguration = UIListContentConfiguration.groupedFooter()
            if let self, let section = self.dataSource.sectionIdentifier(for: indexPath.section) {
                switch section {
                case .pitchYawRow:
                    contentConfiguration.text = CelestiaString("Long press on stepper to change orientation.", comment: "")
                case .zoom:
                    contentConfiguration.text = CelestiaString("Long press on stepper to zoom in/out.", comment: "")
                default:
                    contentConfiguration.text = nil
                }
            }
            supplementaryView.contentConfiguration = contentConfiguration
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self, kind == UICollectionView.elementKindSectionFooter else { return nil }
            return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration, for: indexPath)
        }
        return dataSource
    }()

    private var lastKey: Int?

    private let executor: AsyncProviderExecutor

    #if os(iOS) && !targetEnvironment(macCatalyst)
    private var gyroscopeSettings: GyroscopeSettings
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    public init(executor: AsyncProviderExecutor, gyroscopeSettings: GyroscopeSettings) {
        self.executor = executor
        self.gyroscopeSettings = gyroscopeSettings

        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
            var config = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
            if let self, let section = self.dataSource.sectionIdentifier(for: sectionIndex), section == .pitchYawRow || section == .zoom {
                config.footerMode = .supplementary
            }
            return .list(using: config, layoutEnvironment: environment)
        })
    }
    #else
    public init(executor: AsyncProviderExecutor) {
        self.executor = executor

        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, environment in
            var config = UICollectionLayoutListConfiguration(appearance: .defaultGrouped)
            if let self, let section = self.dataSource.sectionIdentifier(for: sectionIndex), section == .pitchYawRow || section == .zoom {
                config.footerMode = .supplementary
            }
            return .list(using: config, layoutEnvironment: environment)
        })
    }
    #endif

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension CameraControlViewController {
    func setUp() {
        title = CelestiaString("Camera Control", comment: "Observer control")
        windowTitle = title

        collectionView.dataSource = dataSource

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.pitchYawRow, .zoom])

        snapshot.appendItems([.pitchYawRollZoom(.pitch), .pitchYawRollZoom(.yaw), .pitchYawRollZoom(.roll)], toSection: .pitchYawRow)
        snapshot.appendItems([.pitchYawRollZoom(.zoom)], toSection: .zoom)

        #if os(iOS) && !targetEnvironment(macCatalyst)
        snapshot.appendSections([.gyroscope])
        snapshot.appendItems([.gyroscope], toSection: .gyroscope)
        #endif

        snapshot.appendSections([.flightMode, .reverseOrientation])
        snapshot.appendItems([.flightMode], toSection: .flightMode)
        snapshot.appendItems([.reverseOrientation], toSection: .reverseOrientation)

        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

extension CameraControlViewController {
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .flightMode:
            navigationController?.pushViewController(ObserverModeViewController(executor: executor), animated: true)
        case .reverseOrientation:
            Task {
                await executor.run { $0.simulation.reverseObserverOrientation() }
            }
        default:
            break
        }
    }
}

private extension CameraControlViewController {
    private func handleKeyAction(_ keyAction: PitchYawRollZoom, plus: Bool) {
        let key = plus ? keyAction.plusKey : keyAction.minusKey
        if let prev = lastKey {
            if key == prev { return }
            Task {
                await executor.run { $0.keyUp(prev) }
            }
        }

        Task {
            await executor.run { $0.keyDown(key) }
        }
        lastKey = key
    }

    private func handleStop() {
        if let key = lastKey {
            Task {
                await executor.run { $0.keyUp(key) }
            }
            lastKey = nil
        }
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @objc private func gyroscopeSettingsChanged(_ sender: UISwitch) {
        gyroscopeSettings.isEnabled = sender.isOn
    }
    #endif
}
