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
    #if targetEnvironment(macCatalyst)
    case mirror
    #endif

    static var persistentAction: [[AppToolbarAction]] {
        return [[.setting], [.share, .search, .home, .paperplane], [.camera, .time, .script, .speedometer], [.browse, .favorite, .event], [.addons, .download, .newsarchive], [.help]]
    }
}

class ToolbarViewController: UIViewController {
    private enum Constants {
        static let width: CGFloat = 220
        static let separatorContainerHeight: CGFloat = 6
    }

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

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

        setup()
    }

    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: Constants.width, height: 0)
        }
        set {}
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
}

extension ToolbarViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return actions.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actions[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ToolbarCell

        cell.backgroundColor = .clear
        let action = actions[indexPath.section][indexPath.row]
        cell.itemImage = action.image
        cell.itemTitle = action.title
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

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sup = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Separator", for: indexPath) as! ToolbarSeparatorCell
        sup.isHidden = indexPath.section == actions.count - 1
        return sup
    }
}

private extension ToolbarViewController {
    func setup() {
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

        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.scrollDirection = .vertical

        layout.itemSize = UICollectionViewFlowLayout.automaticSize
        layout.estimatedItemSize = CGSize(width: Constants.width, height: GlobalConstants.baseCellHeight)
        layout.footerReferenceSize = CGSize(width: Constants.width, height: Constants.separatorContainerHeight)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let contentView = backgroundView.contentView
        contentView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor)
        ])

        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = false

        collectionView.register(ToolbarSeparatorCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Separator")
        collectionView.register(ToolbarImageTextButtonCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.dataSource = self

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
#if targetEnvironment(macCatalyst)
        case .mirror:
            return UIImage(systemName: "pip")
#endif
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
        #if targetEnvironment(macCatalyst)
        case .mirror:
            return nil
        #endif
        }
    }
}
