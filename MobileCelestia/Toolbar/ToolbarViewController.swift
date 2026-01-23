// ToolbarViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import UIKit

protocol ToolbarAction {
    var image: UIImage? { get }
    var title: String? { get }
}

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
    case feedback
    case plus

    static var persistentAction: [[AppToolbarAction]] {
        var actions: [[AppToolbarAction]] = [[.setting], [.share, .search, .home, .paperplane], [.camera, .time, .script, .speedometer], [.browse, .favorite, .event], [.addons, .download, .newsarchive], [.feedback, .help]]
        actions.insert([.plus], at: 0)
        return actions
    }
}

class ToolbarViewController: UICollectionViewController {
    enum Constants {
        static let width: CGFloat = 220
    }

    private let actions: [[ToolbarAction]]

    private let finishOnSelection: Bool

    private var selectedAction: ToolbarAction?

    var selectionHandler: ((ToolbarAction) -> Void)?

    init(actions: [[ToolbarAction]], finishOnSelection: Bool = true) {
        self.actions = actions
        self.finishOnSelection = finishOnSelection
        let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(SeparatorView.Constants.separatorContainerHeight)), elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
        footer.pinToVisibleBounds = false
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.showsSeparators = false
            configuration.backgroundColor = .clear
            configuration.footerMode = sectionIndex == actions.count - 1 ? .none : .supplementary
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
            if configuration.footerMode == .supplementary {
                section.boundarySupplementaryItems = [footer]
            }
            return section
        }))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

extension ToolbarViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return actions.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actions[section].count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! UICollectionViewListCell

        cell.backgroundConfiguration = .clear()
        let action = actions[indexPath.section][indexPath.item]
        var contentConfiguration = ToolbarEntryConfiguration(itemTitle: action.title, itemImage: action.image)
        contentConfiguration.touchUpHandler = { [unowned self] _, inside in
            guard inside else { return }
            if self.finishOnSelection {
                self.dismiss(animated: true) {
                    self.selectionHandler?(action)
                }
            } else {
                self.selectionHandler?(action)
            }
        }
        cell.contentConfiguration = contentConfiguration
        cell.focusEffect = UIFocusEffect()

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Separator", for: indexPath) as! UICollectionViewListCell
            cell.contentConfiguration = SeparatorConfiguration()
            return cell
        }
        fatalError()
    }
}


private extension ToolbarViewController {
    func setUp() {
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.register(UICollectionViewListCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Separator")

        collectionView.showsVerticalScrollIndicator = false

        view.maximumContentSizeCategory = .extraExtraExtraLarge
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
            return UIImage(systemName: "newspaper")
        case .feedback:
            return UIImage(systemName: "exclamationmark.bubble")
        case .plus:
            return UIImage(systemName: "crown")
        }
    }
}

extension AppToolbarAction {
    var title: String? {
        switch self {
        case .browse:
            return CelestiaString("Star Browser", comment: "")
        case .favorite:
            return CelestiaString("Favorites", comment: "Favorites (currently bookmarks and scripts)")
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
            return CelestiaString("Camera Control", comment: "Observer control")
        case .help:
            return CelestiaString("Help", comment: "")
        case .home:
            return CelestiaString("Home (Sol)", comment: "Home object, sun.")
        case .event:
            return CelestiaString("Eclipse Finder", comment: "")
        case .addons:
            return CelestiaString("Installed Add-ons", comment: "Open a page for managing installed add-ons")
        case .download:
            return CelestiaString("Get Add-ons", comment: "Open webpage for downloading add-ons")
        case .paperplane:
            return CelestiaString("Go to Object", comment: "")
        case .speedometer:
            return CelestiaString("Speed Control", comment: "Speed control")
        case .newsarchive:
            return CelestiaString("News Archive", comment: "Archive for updates and featured content")
        case .feedback:
            return CelestiaString("Send Feedback", comment: "")
        case .plus:
            return CelestiaString("Celestia PLUS", comment: "Name for the subscription service")
        }
    }
}
