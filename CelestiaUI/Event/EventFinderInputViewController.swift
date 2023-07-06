//
// EventFinderInputViewController.swift
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

protocol EventFinderInputItem {
    var title: String { get }
}

class EventFinderInputViewController: BaseTableViewController {
    struct DateItem: EventFinderInputItem {
        let title: String
        let isStartTime: Bool
    }

    struct ObjectItem: EventFinderInputItem {
        let title = CelestiaString("Object", comment: "")
    }

    private let allSections: [[EventFinderInputItem]] = [
                [DateItem(title: CelestiaString("Start Time", comment: ""), isStartTime: true),
                DateItem(title: CelestiaString("End Time", comment: ""), isStartTime: false)],
                [ObjectItem()],
    ]

    private let selectableObjects = [LocalizedString("Earth", "celestia-data"), LocalizedString("Jupiter", "celestia-data")]

    private let defaultSearchingInterval: TimeInterval = 365 * 24 * 60 * 60
    private lazy var startTime = endTime.addingTimeInterval(-defaultSearchingInterval)
    private lazy var endTime = Date()
    private var objectName = LocalizedString("Earth", "celestia-data")

    private let executor: AsyncProviderExecutor

    private lazy var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private let resultHandler: (([Eclipse]) -> Void)
    private let textInputHandler: (_ viewController: UIViewController, _ title: String) async -> String?
    private let dateInputHandler: (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?

    init(
        executor: AsyncProviderExecutor,
        resultHandler: @escaping (([Eclipse]) -> Void),
        textInputHandler: @escaping (_ viewController: UIViewController, _ title: String) async -> String?,
        dateInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?
    ) {
        self.executor = executor
        self.resultHandler = resultHandler
        self.textInputHandler = textInputHandler
        self.dateInputHandler = dateInputHandler

        super.init(style: .defaultGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension EventFinderInputViewController {
    func setup() {
        title = CelestiaString("Eclipse Finder", comment: "")
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CelestiaString("Find", comment: ""), style: .plain, target: self, action: #selector(findEclipse))
    }

    @objc private func findEclipse() {
        Task {
            let objectName = self.objectName
            guard let body = await executor.get({ core in return core.simulation.findObject(from: objectName).body }) else {
                showError(CelestiaString("Object not found", comment: ""))
                return
            }

            let finder = EclipseFinder(body: body)
            let alert = showLoading(CelestiaString("Calculating…", comment: "")) {
                finder.abort()
            }

            let results = await finder.search(kind: [.lunar, .solar], from: self.startTime, to: self.endTime)
            alert.dismiss(animated: true) {
                self.resultHandler(results)
            }
        }
    }
}

extension EventFinderInputViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return allSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allSections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = allSections[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        cell.title = item.title

        if item is ObjectItem {
            cell.detail = objectName
        } else if let it = item as? DateItem {
            cell.detail = displayDateFormatter.string(from: it.isStartTime ? startTime : endTime)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = allSections[indexPath.section][indexPath.row]
        if let it = item as? DateItem {
            let preferredFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMddHHmmss", options: 0, locale: Locale.current) ?? "yyyy/MM/dd HH:mm:ss"
            Task {
                let title = String.localizedStringWithFormat(CelestiaString("Please enter the time in \"%s\" format.", comment: "").toLocalizationTemplate, preferredFormat)
                guard let date = await self.dateInputHandler(self, title, preferredFormat) else {
                    self.showError(CelestiaString("Unrecognized time string.", comment: ""))
                    return
                }
                if it.isStartTime {
                    self.startTime = date
                } else {
                    self.endTime = date
                }
                tableView.reloadData()
            }
        } else if item is ObjectItem {
            if let cell = tableView.cellForRow(at: indexPath) {
                showSelection(CelestiaString("Please choose an object.", comment: ""),
                              options: selectableObjects.map { LocalizedString($0, "celestia-data") } + [CelestiaString("Other", comment: "")],
                              source: .view(view: cell, sourceRect: nil)) { [weak self] index in
                    guard let self = self, let index = index else { return }
                    if index >= self.selectableObjects.count {
                        // User choose other, show text input for the object name
                        Task {
                            if let text = await self.textInputHandler(self, CelestiaString("Please enter an object name.", comment: "")) {
                                self.objectName = text
                                tableView.reloadData()
                            }
                        }
                        return
                    }
                    self.objectName = self.selectableObjects[index]
                    tableView.reloadData()
                }
            }
        }
    }
}

extension EclipseFinder: @unchecked Sendable {}
extension Eclipse: @unchecked Sendable {}

extension EclipseFinder {
    func search(kind: EclipseKind, from: Date, to: Date) async -> [Eclipse] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: self.search(kind: kind, from: from, to: to))
            }
        }
    }
}
