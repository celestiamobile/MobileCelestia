//
//  ToolbarViewController.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/23.
//  Copyright © 2020 李林峰. All rights reserved.
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

    static var persistentAction: [[AppToolbarAction]] {
        return [[.share, .search, .home], [.camera, .time, .script], [.browse, .favorite, .event], [.help], [.setting]]
    }
}

class ToolbarViewController: UIViewController {
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    private let actions: [[ToolbarAction]]

    #if targetEnvironment(macCatalyst)
    private var touchBarActions: [ToolbarTouchBarAction]
    var touchBarActionConversionBlock: ((NSTouchBarItem.Identifier) -> ToolbarTouchBarAction?)?
    #endif

    private let finishOnSelection: Bool
    private let scrollDirection: UICollectionView.ScrollDirection

    private var selectedAction: ToolbarAction?

    var selectionHandler: ((ToolbarAction) -> Void)?

    init(actions: [[ToolbarAction]], scrollDirection: UICollectionView.ScrollDirection = .vertical, finishOnSelection: Bool = true) {
        self.actions = actions
        #if targetEnvironment(macCatalyst)
        self.touchBarActions = actions.reduce([], { $0 + $1.compactMap { $0 as? ToolbarTouchBarAction } })
        #endif
        self.scrollDirection = scrollDirection
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
            if scrollDirection == .horizontal {
                return CGSize(width: CGFloat(60 * actions.reduce(0, { $0 + $1.count }) + 16), height: 60 + 8)
            }
            return CGSize(width: 220, height: 0)
        }
        set {}
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
        cell.actionHandler = { [unowned self] in
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
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.trailingAnchor.constraint(equalTo: view!.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: view!.topAnchor),
        ])
        if scrollDirection == .horizontal {
            NSLayoutConstraint.activate([
                backgroundView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: scrollDirection == .horizontal ? 16 : 0),
                backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: scrollDirection == .horizontal ? -8 : 0)
            ])
        } else {
            NSLayoutConstraint.activate([
                backgroundView.leadingAnchor.constraint(equalTo: view!.leadingAnchor, constant: scrollDirection == .horizontal ? 16 : 0),
                backgroundView.bottomAnchor.constraint(equalTo: view!.bottomAnchor, constant: scrollDirection == .horizontal ? -8 : 0)
            ])
        }

        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.scrollDirection = scrollDirection

        if scrollDirection == .vertical {
            layout.itemSize = CGSize(width: 220, height: 44)
            layout.footerReferenceSize = CGSize(width: 200, height: 6)
        } else {
            layout.itemSize = CGSize(width: 60, height: 60)
            backgroundView.layer.masksToBounds = true
            backgroundView.layer.cornerRadius = 8
        }
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let contentView = backgroundView.contentView
        contentView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        if scrollDirection == .horizontal {
            NSLayoutConstraint.activate([
                collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])

            if #available(iOS 11.0, *) {
                NSLayoutConstraint.activate([
                    collectionView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
                    collectionView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
                    collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ])
            }
        } else {
            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
                collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])

            if #available(iOS 11.0, *) {
                NSLayoutConstraint.activate([
                    collectionView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
                    collectionView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
                ])
            }
        }

        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = false

        if scrollDirection == .horizontal {
            collectionView.register(ToolbarImageButtonCell.self, forCellWithReuseIdentifier: "Cell")
        } else {
            collectionView.register(ToolbarSeparatorCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Separator")
            collectionView.register(ToolbarImageTextButtonCell.self, forCellWithReuseIdentifier: "Cell")
        }
        collectionView.dataSource = self
    }
}

#if targetEnvironment(macCatalyst)
extension ToolbarViewController: NSTouchBarDelegate {
    private var closeTouchBarIdentifier: NSTouchBarItem.Identifier {
        return NSTouchBarItem.Identifier(rawValue: "close")
    }

    override func makeTouchBar() -> NSTouchBar? {
        guard touchBarActions.count > 0 else { return nil }
        let tbar = NSTouchBar()
        tbar.defaultItemIdentifiers = touchBarActions.map { $0.touchBarItemIdentifier } + [closeTouchBarIdentifier]
        tbar.delegate = self
        return tbar
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        if identifier == closeTouchBarIdentifier {
            return NSButtonTouchBarItem(identifier: identifier, image: UIImage(systemName: "xmark.circle.fill") ?? UIImage(), target: self, action: #selector(requestClose))
        }
        guard let action = touchBarActionConversionBlock?(identifier) else { return nil }
        if let image = action.touchBarImage {
            return NSButtonTouchBarItem(identifier: identifier, image: image, target: self, action: #selector(touchBarButtonItemClicked(_:)))
        }
        return NSButtonTouchBarItem(identifier: identifier, title: action.title ?? "", target: self, action: #selector(touchBarButtonItemClicked(_:)))
    }

    @objc private func touchBarButtonItemClicked(_ sender: NSTouchBarItem) {
        guard let action = touchBarActionConversionBlock?(sender.identifier) else { return }
        if finishOnSelection {
            dismiss(animated: true, completion: nil)
        }
        selectionHandler?(action)
    }

    @objc private func requestClose() {
        dismiss(animated: true, completion: nil)
    }
}
#endif

extension AppToolbarAction: ToolbarAction {
    var image: UIImage? { return UIImage(named: "toolbar_\(rawValue)") }
}

extension AppToolbarAction {
    var title: String? {
        switch self {
        case .browse:
            return CelestiaString("Browser", comment: "")
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
            return CelestiaString("Event Finder", comment: "")
        }
    }
}
