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
        let title = CelestiaString("Object", comment: "In eclipse finder, object to find eclipse with, or in go to")
    }

    private let allSections: [[EventFinderInputItem]] = [
                [DateItem(title: CelestiaString("Start Time", comment: "In eclipse finder, range of time to find eclipse in"), isStartTime: true),
                DateItem(title: CelestiaString("End Time", comment: "In eclipse finder, range of time to find eclipse in"), isStartTime: false)],
                [ObjectItem()],
    ]

    private let selectableObjects: [(displayName: String, objectPath: String)] = [(LocalizedString("Earth", "celestia-data"), "Sol/Earth"), (LocalizedString("Jupiter", "celestia-data"), "Sol/Jupiter")]

    private let defaultSearchingInterval: TimeInterval = 365 * 24 * 60 * 60
    private lazy var startTime = endTime.addingTimeInterval(-defaultSearchingInterval)
    private lazy var endTime = Date()
    private var objectName = LocalizedString("Earth", "celestia-data")
    private var objectPath = "Sol/Earth"

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
        windowTitle = title
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CelestiaString("Find", comment: "Find (eclipses)"), style: .plain, target: self, action: #selector(findEclipse))
    }

    @objc private func findEclipse() {
        Task {
            let objectPath = self.objectPath
            guard let body = await executor.get({ core in return core.simulation.findObject(from: objectPath).body }) else {
                showError(CelestiaString("Object not found", comment: ""))
                return
            }

            let finder = EclipseFinder(body: body)
            let alert = showLoading(CelestiaString("Calculating…", comment: "Calculating for eclipses")) {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
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
                let title = String.localizedStringWithFormat(CelestiaString("Please enter the time in \"%@\" format.", comment: ""), preferredFormat)
                guard let date = await self.dateInputHandler(self, title, preferredFormat) else {
                    self.showError(CelestiaString("Unrecognized time string.", comment: "String not in correct format"))
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
                showSelection(CelestiaString("Please choose an object.", comment: "In eclipse finder, choose an object to find eclipse wth"),
                              options: selectableObjects.map { $0.displayName } + [CelestiaString("Other", comment: "Other location labels; Android/iOS, Other objects to choose from in Eclipse Finder")],
                              source: .view(view: cell, sourceRect: nil)) { [weak self] index in
                    guard let self = self, let index = index else { return }
                    if index >= self.selectableObjects.count {
                        // User choose other, show text input for the object name
                        Task {
                            if let text = await self.textInputHandler(self, CelestiaString("Please enter an object name.", comment: "In Go to; Android/iOS, Enter the name of an object in Eclipse Finder")) {
                                self.objectName = text
                                self.objectPath = text
                                tableView.reloadData()
                            }
                        }
                        return
                    }
                    self.objectName = self.selectableObjects[index].displayName
                    self.objectPath = self.selectableObjects[index].objectPath
                    tableView.reloadData()
                }
            }
        }
    }
}

extension Body: @unchecked @retroactive Sendable {}
extension EclipseFinder: @unchecked @retroactive Sendable {}

extension EclipseFinder {
    func search(kind: EclipseKind, from: Date, to: Date) async -> [Eclipse] {
        return await Task.detached(priority: .background) {
            self.search(kind: kind, from: from, to: to)
        }.value
    }
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: GoToInputViewController.self).bundleIdentifier!
    fileprivate static let calculate = NSToolbarItem.Identifier.init("\(prefix).calculate")
}

extension EventFinderInputViewController: ToolbarAwareViewController {
    func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier] {
        return [.calculate]
    }

    func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        if itemIdentifier == .calculate {
            return NSToolbarItem(itemIdentifier: itemIdentifier, buttonTitle: CelestiaString("Find", comment: "Find (eclipses)"), target: self, action: #selector(findEclipse))
        }
        return nil
    }
}
#endif
