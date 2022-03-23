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
        #if targetEnvironment(macCatalyst)
        return [[.setting], [.share, .search, .home, .paperplane], [.time, .script, .speedometer], [.browse, .favorite, .event], [.addons, .download, .newsarchive], [.help]]
        #else
        return [[.setting], [.share, .search, .home, .paperplane], [.camera, .time, .script, .speedometer], [.browse, .favorite, .event], [.addons, .download, .newsarchive], [.help]]
        #endif
    }
}

class ToolbarViewController: UIViewController {
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

        NotificationCenter.default.addObserver(self, selector: #selector(handleContentSizeCategoryChanged), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 220, height: 0)
        }
        set {}
    }

    @objc private func handleContentSizeCategoryChanged() {
        collectionView.collectionViewLayout.invalidateLayout()
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
                self.dismiss(animated: true, completion: nil)
            }
            self.selectionHandler?(action)
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
        let style: UIBlurEffect.Style
        if #available(iOS 13.0, *) {
            style = .regular
        } else {
            style = .dark
        }
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

        layout.itemSize = CGSize(width: 220, height: 44)
        layout.estimatedItemSize = layout.itemSize
        layout.footerReferenceSize = CGSize(width: 200, height: 6)
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
    }
}

extension AppToolbarAction: ToolbarAction {
    var image: UIImage? { return UIImage(named: "toolbar_\(rawValue)") }
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
            return CelestiaString("Manage Installed Add-ons", comment: "")
        case .download:
            return CelestiaString("Download Add-ons", comment: "")
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
