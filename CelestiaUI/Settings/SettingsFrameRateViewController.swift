//
// SettingsFrameRateViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#if !os(visionOS)
import UIKit

class SettingsFrameRateViewController: UICollectionViewController {
    private struct FrameRateItem {
        let frameRate: Int
        let isMaximum: Bool

        var frameRateValue: Int {
            return isMaximum ? -1 : frameRate
        }
    }

    private var items: [FrameRateItem] = []
    private let userDefaults: UserDefaults
    private let userDefaultsKey: String

    private let frameRateUpdateHandler: (Int) -> Void
    private let screen: UIScreen

    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    init(screen: UIScreen, userDefaults: UserDefaults, userDefaultsKey: String, frameRateUpdateHandler: @escaping (Int) -> Void) {
        self.screen = screen
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey
        self.frameRateUpdateHandler = frameRateUpdateHandler
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: .init(appearance: .defaultGrouped)))
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
        let maxFrameRate = screen.maximumFramesPerSecond

        var standardFrameRate = [
            FrameRateItem(frameRate: 60, isMaximum: false),
            FrameRateItem(frameRate: 30, isMaximum: false),
            FrameRateItem(frameRate: 20, isMaximum: false),
        ].filter({ $0.frameRate <= maxFrameRate })

        standardFrameRate.insert(FrameRateItem(frameRate: maxFrameRate, isMaximum: true), at: 0)

        items = standardFrameRate
        collectionView.reloadData()
    }
}

private extension SettingsFrameRateViewController {
    func setUp() {
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "Text")
        title = CelestiaString("Frame Rate", comment: "Frame rate of simulation")
        windowTitle = title
    }
}

extension SettingsFrameRateViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let selectedFrameRate: Int = userDefaults.value(forKey: userDefaultsKey) as? Int ?? 60
        let item = items[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Text", for: indexPath) as! UICollectionViewListCell
        var configuration = UIListContentConfiguration.celestiaCell()
        configuration.text = String.localizedStringWithFormat(item.isMaximum ? CelestiaString("Maximum (%@ FPS)", comment: "") : CelestiaString("%@ FPS", comment: ""), numberFormatter.string(from: item.frameRate))
        cell.contentConfiguration = configuration
        cell.accessories = item.frameRateValue == selectedFrameRate ? [.checkmark()] : []
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let item = items[indexPath.item]
        frameRateUpdateHandler(item.frameRateValue)
        collectionView.reloadData()
    }
}
#endif
