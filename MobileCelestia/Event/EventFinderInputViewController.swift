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

import UIKit

import CelestiaCore

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

    struct ProceedItem: EventFinderInputItem {
        let title = CelestiaString("Find", comment: "")
    }

    private let allSections: [[EventFinderInputItem]] = [
                [DateItem(title: CelestiaString("Start Time", comment: ""), isStartTime: true),
                DateItem(title: CelestiaString("End Time", comment: ""), isStartTime: false)],
                [ObjectItem()],
                [ProceedItem()]
    ]

    private let selectableObjects = [LocalizedString("Earth", "celestia"), LocalizedString("Jupiter", "celestia")]

    private let defaultSearchingInterval: TimeInterval = 365 * 24 * 60 * 60
    private lazy var startTime = endTime.addingTimeInterval(-defaultSearchingInterval)
    private lazy var endTime = Date()
    private var objectName = LocalizedString("Earth", "celestia")

    private let core = AppCore.shared

    private lazy var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private let resultHandler: (([Eclipse]) -> Void)

    init(resultHandler: @escaping (([Eclipse]) -> Void)) {
        self.resultHandler = resultHandler
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

        if item is ProceedItem {
            #if targetEnvironment(macCatalyst)
            cell.titleColor = cell.tintColor
            #else
            cell.titleColor = UIColor.themeLabel
            #endif
            cell.detail = nil
        } else if item is ObjectItem {
            cell.titleColor = UIColor.darkLabel
            cell.detail = objectName
        } else if let it = item as? DateItem {
            cell.titleColor = UIColor.darkLabel
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
            showDateInput(String(format: CelestiaString("Please enter the time in \"%s\" format.", comment: "").toLocalizationTemplate, preferredFormat), format: preferredFormat) { [weak self] (result) in
                guard let self = self else { return }

                guard let date = result else {
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
                              options: selectableObjects.map { LocalizedString($0, "celestia") } + [CelestiaString("Other", comment: "")],
                              sourceView: cell, sourceRect: cell.bounds) { [weak self] index in
                    guard let self = self, let index = index else { return }
                    if index >= self.selectableObjects.count {
                        // User choose other, show text input for the object name
                        self.showTextInput(CelestiaString("Please enter an object name.", comment: "")) { text in
                            guard let objectName = text else { return }
                            self.objectName = objectName
                            tableView.reloadData()
                        }
                        return
                    }
                    self.objectName = self.selectableObjects[index]
                    tableView.reloadData()
                }
            }
        } else if item is ProceedItem {
            guard let body = core.simulation.findObject(from: objectName).body else {
                self.showError(CelestiaString("Object not found", comment: ""))
                return
            }
            let finder = EcipseFinder(body: body)
            let alert = showLoading(CelestiaString("Calculating…", comment: "")) {
                finder.abort()
            }
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                let results = finder.search(kind: [.lunar, .solar], from: self.startTime, to: self.endTime)

                DispatchQueue.main.async {
                    alert.dismiss(animated: true) {
                        self.resultHandler(results)
                    }
                }
            }
        }
    }
}
