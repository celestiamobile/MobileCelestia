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

import UIKit

public class SettingsFrameRateViewController: BaseTableViewController {
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

    public init(screen: UIScreen, userDefaults: UserDefaults, userDefaultsKey: String, frameRateUpdateHandler: @escaping (Int) -> Void) {
        self.screen = screen
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey
        self.frameRateUpdateHandler = frameRateUpdateHandler
        super.init(style: .defaultGrouped)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    public override func viewWillAppear(_ animated: Bool) {
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
        tableView.reloadData()
    }
}

private extension SettingsFrameRateViewController {
    func setUp() {
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        title = CelestiaString("Frame Rate", comment: "")
    }
}

extension SettingsFrameRateViewController {
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let selectedFrameRate: Int = userDefaults.value(forKey: userDefaultsKey) as? Int ?? 60
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
        cell.title = String.localizedStringWithFormat(CelestiaString(item.isMaximum ? "Maximum (%d FPS)" : "%d FPS", comment: ""), item.frameRate)
        cell.accessoryType = item.frameRateValue == selectedFrameRate ? .checkmark : .none
        return cell
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        frameRateUpdateHandler(item.frameRateValue)
        tableView.reloadData()
    }
}
