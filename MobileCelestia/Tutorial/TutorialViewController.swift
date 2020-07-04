//
// TutorialViewController.swift
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

enum TutorialAction {
    case runDemo
}

class TutorialViewController: UIViewController {
    private struct TutorialDescriptionItem {
        let image: UIImage?
        let text: String
    }

    private struct TutorialActionItem {
        let title: String
        let object: TutorialAction
    }

    private enum TutorialItem {
        case description(item: TutorialDescriptionItem)
        case action(item: TutorialActionItem)
    }

    private lazy var tableView = UITableView(frame: .zero, style: .plain)

    private lazy var tutorialDescriptionItems = [
        TutorialDescriptionItem(image: #imageLiteral(resourceName: "tutorial_switch_mode"),
                                text: CelestiaString("Tap the mode button on the sidebar to switch between object mode and camera mode.", comment: "")),
        TutorialDescriptionItem(image: #imageLiteral(resourceName: "tutorial_mode_object"),
                                text: CelestiaString("In object mode, drag to rotate around an object.\n\nPinch to zoom in/out on an object.", comment: "")),
        TutorialDescriptionItem(image: #imageLiteral(resourceName: "tutorial_mode_camera"),
                                text: CelestiaString("In camera mode, drag to move field of view.\n\nPinch to zoom in/out field of view.", comment: "")),
    ]

    private lazy var tutorialActionItems = [
        TutorialActionItem(title: CelestiaString("Run Demo", comment: ""), object: .runDemo)
    ]

    private lazy var tutorialItems: [[TutorialItem]] = [
        self.tutorialDescriptionItems.map { TutorialItem.description(item: $0) },
        self.tutorialActionItems.map { TutorialItem.action(item: $0) }
    ]

    private let actionHandler: ((TutorialAction) -> Void)?

    init(actionHandler: ((TutorialAction) -> Void)?) {
        self.actionHandler = actionHandler
        super.init(nibName: nil, bundle: nil)

        title = CelestiaString("Tutorial", comment: "")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkSecondaryBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

private extension TutorialViewController {
    func setup() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.tableFooterView = UIView()

        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.alwaysBounceVertical = false
        tableView.separatorStyle = .none

        tableView.register(TutorialDescriptionCell.self, forCellReuseIdentifier: "Description")
        tableView.register(TutorialActionCell.self, forCellReuseIdentifier: "Action")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension TutorialViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tutorialItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tutorialItems[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tutorialItems[indexPath.section][indexPath.row]
        switch item {
        case .description(let desc):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Description", for: indexPath) as! TutorialDescriptionCell
            cell.title = desc.text
            cell.img = desc.image
            return cell
        case .action(let action):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Action", for: indexPath) as! TutorialActionCell
            cell.title = action.title
            cell.actionHandler = { [unowned self] in
                self.actionHandler?(action.object)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = tutorialItems[indexPath.section][indexPath.row]
        switch item {
        case .description(_):
            return UITableView.automaticDimension
        case .action(_):
            return 60
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
