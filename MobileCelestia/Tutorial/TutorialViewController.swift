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

import CelestiaCore
import CelestiaUI
import UIKit

enum TutorialAction {
    case runDemo
}

class TutorialViewController: BaseTableViewController {
    private struct TutorialDescriptionItem {
        let image: UIImage?
        let text: String
    }

    private struct TutorialActionItem {
        let title: String
        let object: TutorialAction
    }

    private struct TutorialURLItem {
        let title: String
        let url: URL
    }

    private enum TutorialItem {
        case description(item: TutorialDescriptionItem)
        case action(item: TutorialActionItem)
        case url(url: TutorialURLItem)
    }

    #if !targetEnvironment(macCatalyst)
    private lazy var tutorialDescriptionItems = [
        TutorialDescriptionItem(image: UIImage(named: "tutorial_switch_mode"),
                                text: CelestiaString("Tap the mode button on the sidebar to switch between object mode and camera mode.", comment: "")),
        TutorialDescriptionItem(image: UIImage(systemName: "cube") ?? UIImage(named: "tutorial_mode_object"),
                                text: CelestiaString("In object mode, drag to rotate around an object.\n\nPinch to zoom in/out on an object.", comment: "")),
        TutorialDescriptionItem(image: UIImage(systemName: "video") ?? UIImage(named: "tutorial_mode_camera"),
                                text: CelestiaString("In camera mode, drag to move field of view.\n\nPinch to zoom in/out field of view.", comment: "")),
    ]
    #else
    private lazy var tutorialDescriptionItems: [TutorialDescriptionItem] = []
    #endif

    private lazy var tutorialActionItems = [
        TutorialActionItem(title: CelestiaString("Run Demo", comment: ""), object: .runDemo),
    ]

    private lazy var urlItems = [
        TutorialURLItem(title: CelestiaString("Mouse/Keyboard Controls", comment: ""), url: URL(string: "celguide://guide?guide=BE1B5023-46B6-1F10-F15F-3B3F02F30300")!),
        TutorialURLItem(title: CelestiaString("Use Add-ons and Scripts", comment: ""), url: URL(string: "celguide://guide?guide=D1A96BFA-00BB-0089-F361-10DD886C8A4F")!),
        TutorialURLItem(title: CelestiaString("Scripts and URLs", comment: ""), url: URL(string: "celguide://guide?guide=A0AB3F01-E616-3C49-0934-0583D803E9D0")!),
    ]

    private lazy var tutorialItems: [[TutorialItem]] = [
        self.tutorialDescriptionItems.map { TutorialItem.description(item: $0) },
        self.urlItems.map { TutorialItem.url(url: $0) },
        self.tutorialActionItems.map { TutorialItem.action(item: $0) }
    ]

    private let actionHandler: ((TutorialAction) -> Void)?
    private let urlHandler: ((URL) -> Void)?

    init(actionHandler: ((TutorialAction) -> Void)?, urlHandler: ((URL) -> Void)?) {
        self.actionHandler = actionHandler
        self.urlHandler = urlHandler
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension TutorialViewController {
    func setup() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.register(TutorialDescriptionCell.self, forCellReuseIdentifier: "Description")
        tableView.register(TutorialActionCell.self, forCellReuseIdentifier: "Action")
        tableView.register(TutorialActionCell.self, forCellReuseIdentifier: "URL")
        title = CelestiaString("Tutorial", comment: "")
    }
}

extension TutorialViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tutorialItems.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tutorialItems[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        case .url(let url):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Action", for: indexPath) as! TutorialActionCell
            cell.title = url.title
            cell.actionHandler = { [unowned self] in
                self.urlHandler?(url.url)
            }
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
