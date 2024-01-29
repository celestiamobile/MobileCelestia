//
// TimeSettingViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

public class TimeSettingViewController: BaseTableViewController {
    private let core: AppCore
    private let executor: AsyncProviderExecutor
    private let dateInputHandler: (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?
    private let textInputHandler: (_ viewController: UIViewController, _ title: String, _ keyboardType: UIKeyboardType) async -> String?

    private lazy var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    private lazy var displayNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    public init(
        core: AppCore,
        executor: AsyncProviderExecutor,
        dateInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?,
        textInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ keyboardType: UIKeyboardType) async -> String?
    ) {
        self.core = core
        self.executor = executor
        self.dateInputHandler = dateInputHandler
        self.textInputHandler = textInputHandler
        super.init(style: .defaultGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension TimeSettingViewController {
    func setUp() {
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        title = CelestiaString("Current Time", comment: "")
    }
}

extension TimeSettingViewController {
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
        if indexPath.row == 0 {
            cell.title = CelestiaString("Select Time", comment: "Select simulation time")
            cell.detail = displayDateFormatter.string(from: core.simulation.time)
        } else if indexPath.row == 1 {
            cell.title = CelestiaString("Julian Day", comment: "Select time via entering Julian day")
            cell.detail = displayNumberFormatter.string(from: (core.simulation.time as NSDate).julianDay)
        } else {
            cell.title = CelestiaString("Set to Current Time", comment: "Set simulation time to device")
            cell.detail = nil
        }
        return cell
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            let preferredFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMddHHmmss", options: 0, locale: Locale.current) ?? "yyyy/MM/dd HH:mm:ss"
            let title = String.localizedStringWithFormat(CelestiaString("Please enter the time in \"%@\" format.", comment: ""), preferredFormat)
            Task {
                guard let date = await dateInputHandler(self, title, preferredFormat) else {
                    self.showError(CelestiaString("Unrecognized time string.", comment: "String not in correct format"))
                    return
                }
                await self.executor.run { core in
                    core.simulation.time = date
                }
                self.tableView.reloadData()
            }
        } else if indexPath.row == 1 {
            Task {
                guard let text = await textInputHandler(self, CelestiaString("Please enter Julian day.", comment: "In time settings, enter Julian day for the simulation"), .decimalPad) else {
                    return
                }
                let numberFormatter = NumberFormatter()
                numberFormatter.usesGroupingSeparator = false
                guard let value = numberFormatter.number(from: text)?.doubleValue else {
                    self.showError(CelestiaString("Invalid Julian day string.", comment: "The input of julian day is not valid"))
                    return
                }
                await self.executor.run { core in
                    core.simulation.time = NSDate(julian: value) as Date
                }
                self.tableView.reloadData()
            }
        } else if indexPath.row == 2 {
            Task {
                await executor.run {
                    $0.receive(.currentTime)
                }
                self.tableView.reloadData()
            }
        }
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
