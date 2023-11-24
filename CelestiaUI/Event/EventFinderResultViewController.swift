//
// EventFinderResultViewController.swift
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

class EventFinderResultViewController: BaseTableViewController {
    private lazy var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private let eventHandler: ((Eclipse) -> Void)
    private let events: [Eclipse]

    init(results: [Eclipse], eventHandler: @escaping ((Eclipse) -> Void)) {
        self.eventHandler = eventHandler
        self.events = results
        super.init(style: .defaultGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }
}

private extension EventFinderResultViewController {
    func setUp() {
        tableView.register(TextCell.self, forCellReuseIdentifier: "Text")
        title = CelestiaString("Eclipse Finder", comment: "")

        if events.isEmpty {
            let view = EmptyHintView()
            view.title = CelestiaString("No eclipse is found for the given object in the time range", comment: "")
            tableView.backgroundView = view
        }
    }
}

extension EventFinderResultViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = events[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! TextCell
        cell.title = "\(event.occulter.name) -> \(event.receiver.name)"
        cell.detail = displayDateFormatter.string(from: event.startTime)

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        eventHandler(events[indexPath.row])
    }
}

