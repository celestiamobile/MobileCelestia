//
// TimeSettingViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

public class TimeSettingViewController: BaseTableViewController {
    private let core: AppCore
    private let executor: AsyncProviderExecutor
    private let dateInputHandler: (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?

    private lazy var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    public init(
        core: AppCore,
        executor: AsyncProviderExecutor,
        dateInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?
    ) {
        self.core = core
        self.executor = executor
        self.dateInputHandler = dateInputHandler
        super.init(style: .defaultGrouped)
    }
    
    public required init?(coder: NSCoder) {
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
        return 2
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
        if indexPath.row == 0 {
            cell.title = CelestiaString("Select Time", comment: "")
            cell.detail = displayDateFormatter.string(from: core.simulation.time)
        } else {
            cell.title = CelestiaString("Set to Current Time", comment: "")
            cell.detail = nil
        }

        return cell
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            let preferredFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMddHHmmss", options: 0, locale: Locale.current) ?? "yyyy/MM/dd HH:mm:ss"
            let title = String.localizedStringWithFormat(CelestiaString("Please enter the time in \"%s\" format.", comment: "").toLocalizationTemplate, preferredFormat)
            Task {
                guard let date = await dateInputHandler(self, title, preferredFormat) else {
                    self.showError(CelestiaString("Unrecognized time string.", comment: ""))
                    return
                }
                await self.executor.run { core in
                    core.simulation.time = date
                }
                self.tableView.reloadData()
            }
        } else {
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
