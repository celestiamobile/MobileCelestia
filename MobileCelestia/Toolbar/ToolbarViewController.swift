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

extension ToolbarAction {
    var title: String? { return nil }
}

enum AppToolbarAction: String {
    case celestia
    case setting
    case share
    case search
    case time
    case script
    case camera
    case browse
    case help
    case favorite

    static var persistentAction: [[AppToolbarAction]] {
        return [[.share, .search], [.camera, .time, .script], [.browse, .favorite], [.help], [.setting]]
    }
}

class ToolbarViewController: UIViewController {
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    private let actions: [[ToolbarAction]]
    private let finishOnSelection: Bool
    private let scrollDirection: UICollectionView.ScrollDirection

    private var selectedAction: ToolbarAction?

    var selectionHandler: ((ToolbarAction?) -> Void)?

    init(actions: [[ToolbarAction]], scrollDirection: UICollectionView.ScrollDirection = .vertical, finishOnSelection: Bool = true) {
        self.actions = actions
        self.scrollDirection = scrollDirection
        self.finishOnSelection = finishOnSelection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override var preferredContentSize: CGSize {
        get { return CGSize(width: 220, height: 60) }
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
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.scrollDirection = scrollDirection

        if scrollDirection == .vertical {
            layout.itemSize = CGSize(width: 220, height: 44)
            layout.footerReferenceSize = CGSize(width: 200, height: 6)
        } else {
            layout.itemSize = CGSize(width: 60, height: 60)
        }
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let contentView = (view as! UIVisualEffectView).contentView
        contentView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        if scrollDirection == .horizontal {
            NSLayoutConstraint.activate([
                collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])

            if #available(iOS 11.0, *) {
                NSLayoutConstraint.activate([
                    collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                    collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    collectionView.topAnchor.constraint(equalTo: view.topAnchor),
                    collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            }
        } else {
            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraint(equalTo: view.topAnchor),
                collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])

            if #available(iOS 11.0, *) {
                NSLayoutConstraint.activate([
                    collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                    collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
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

extension AppToolbarAction: ToolbarAction {
    var image: UIImage? { return UIImage(named: "toolbar_\(rawValue)") }
}

extension AppToolbarAction {
    var title: String? {
        switch self {
        case .celestia:
            return CelestiaString("Information", comment: "")
        case .browse:
            return CelestiaString("Browser", comment: "")
        case .favorite:
            return CelestiaString("Favorite", comment: "")
        case .search:
            return CelestiaString("Search", comment: "")
        case .setting:
            return CelestiaString("Setting", comment: "")
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
        }
    }
}
