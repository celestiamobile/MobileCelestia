//
// ToolbarViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import UIKit

protocol ToolbarAction {
    var image: UIImage? { get }
    var title: String? { get }
}

#if targetEnvironment(macCatalyst)
protocol ToolbarTouchBarAction: ToolbarAction {
    var touchBarImage: UIImage? { get }
    var touchBarItemIdentifier: NSTouchBarItem.Identifier { get }
    init?(_ touchBarItemIdentifier: NSTouchBarItem.Identifier)
}
#endif

extension ToolbarAction {
    var title: String? { return nil }
}

enum AppToolbarAction: String {
    case setting
    case share
    case search
    case time
    case script
    case camera
    case browse
    case help
    case favorite
    case home
    case event
    case addons
    case download
    case paperplane
    case speedometer
    case newsarchive

    static var persistentAction: [[AppToolbarAction]] {
        return [[.setting], [.share, .search, .home, .paperplane], [.camera, .time, .script, .speedometer], [.browse, .favorite, .event], [.addons, .download, .newsarchive], [.help]]
    }
}

class ToolbarViewController: UIViewController {
    enum Constants {
        static let width: CGFloat = 220
        static let separatorContainerHeight: CGFloat = 6
    }

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private let actions: [[ToolbarAction]]

    private let finishOnSelection: Bool

    private var selectedAction: ToolbarAction?

    var selectionHandler: ((ToolbarAction) -> Void)?

    init(actions: [[ToolbarAction]], finishOnSelection: Bool = true) {
        self.actions = actions
        self.finishOnSelection = finishOnSelection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUp()
    }

    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: Constants.width, height: 0)
        }
        set {}
    }
}

extension ToolbarViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! (UITableViewCell & ToolbarCell)

        cell.backgroundColor = .clear
        let action = actions[indexPath.section][indexPath.row]
        cell.itemImage = action.image
        cell.itemTitle = action.title
        if #available(iOS 15.0, *) {
            cell.focusEffect = UIFocusEffect()
        }
        cell.touchUpHandler = { [unowned self] _, inside in
            guard inside else { return }
            if self.finishOnSelection {
                self.dismiss(animated: true) {
                    self.selectionHandler?(action)
                }
            } else {
                self.selectionHandler?(action)
            }
        }

        return cell
    }
}

extension ToolbarViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == actions.count - 1 { return nil }
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "Separator")
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == actions.count - 1 { return CGFloat.leastNonzeroMagnitude }
        return Constants.separatorContainerHeight
    }
}

private extension ToolbarViewController {
    func setUp() {
        #if targetEnvironment(macCatalyst)
        let sidebackBackground: Bool
        if #available(macCatalyst 16.0, *) {
            sidebackBackground = true
        } else {
            sidebackBackground = false
        }
        #else
        let sidebackBackground = false
        #endif

        tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: CGFloat.leastNonzeroMagnitude)))
        tableView.tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: CGFloat.leastNonzeroMagnitude)))
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = GlobalConstants.baseCellHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        if !sidebackBackground {
            let style: UIBlurEffect.Style = .regular
            let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: style))
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(backgroundView)

            NSLayoutConstraint.activate([
                backgroundView.trailingAnchor.constraint(equalTo: view!.trailingAnchor),
                backgroundView.topAnchor.constraint(equalTo: view!.topAnchor),
                backgroundView.leadingAnchor.constraint(equalTo: view!.leadingAnchor),
                backgroundView.bottomAnchor.constraint(equalTo: view!.bottomAnchor)
            ])

            let contentView = backgroundView.contentView
            contentView.addSubview(tableView)

            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
                tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])

            NSLayoutConstraint.activate([
                tableView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor)
            ])
        } else {
            view.addSubview(tableView)
            NSLayoutConstraint.activate([
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.topAnchor.constraint(equalTo: view.topAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .clear

        tableView.register(ToolbarSeparatorCell.self, forHeaderFooterViewReuseIdentifier: "Separator")
        tableView.register(ToolbarImageTextButtonCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self

        if #available(iOS 15, *) {
            view.maximumContentSizeCategory = .extraExtraExtraLarge
        }
    }
}

extension AppToolbarAction: ToolbarAction {
    var image: UIImage? {
        switch self {
        case .search:
            return UIImage(systemName: "magnifyingglass")
        case .share:
            return UIImage(systemName: "square.and.arrow.up")
        case .setting:
            return UIImage(systemName: "gear")
        case .browse:
            return UIImage(systemName: "globe")
        case .favorite:
            return UIImage(systemName: "star.circle")
        case .camera:
            return UIImage(systemName: "video")
        case .time:
            return UIImage(systemName: "clock")
        case .script:
            return UIImage(systemName: "doc")
        case .help:
            return UIImage(systemName: "questionmark.circle")
        case .addons:
            return UIImage(systemName: "folder")
        case .download:
            return UIImage(systemName: "square.and.arrow.down")
        case .home:
            return UIImage(systemName: "house")
        case .event:
            return UIImage(systemName: "calendar")
        case .paperplane:
            return UIImage(systemName: "paperplane")
        case .speedometer:
            return UIImage(systemName: "speedometer")
        case .newsarchive:
            return UIImage(systemName: "newspaper") ?? UIImage(named: "toolbar_newsarchive")
        }
    }
}

extension AppToolbarAction {
    var title: String? {
        switch self {
        case .browse:
            return CelestiaString("Star Browser", comment: "")
        case .favorite:
            return CelestiaString("Favorites", comment: "")
        case .search:
            return CelestiaString("Search", comment: "")
        case .setting:
            return CelestiaString("Settings", comment: "")
        case .share:
            return CelestiaString("Share", comment: "")
        case .time:
            return CelestiaString("Time Control", comment: "")
        case .script:
            return CelestiaString("Script Control", comment: "")
        case .camera:
            return CelestiaString("Camera Control", comment: "")
        case .help:
            return CelestiaString("Help", comment: "")
        case .home:
            return CelestiaString("Home (Sol)", comment: "")
        case .event:
            return CelestiaString("Eclipse Finder", comment: "")
        case .addons:
            return CelestiaString("Installed Add-ons", comment: "")
        case .download:
            return CelestiaString("Get Add-ons", comment: "")
        case .paperplane:
            return CelestiaString("Go to Object", comment: "")
        case .speedometer:
            return CelestiaString("Speed Control", comment: "")
        case .newsarchive:
            return CelestiaString("News Archive", comment: "")
        }
    }
}
