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
}

enum AppToolbarAction: String {
    case celestia
    case setting
    case share
    case search
    case time
    case browse
    case favorite

    static var persistentAction: [AppToolbarAction] {
        return [.share, .search, .time, .browse, .favorite, .setting]
    }
}

class ToolbarViewController: UIViewController {
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    private let actions: [ToolbarAction]
    private let finishOnSelection: Bool
    private let scrollDirection: UICollectionView.ScrollDirection

    private var selectedAction: ToolbarAction?

    var selectionHandler: ((ToolbarAction?) -> Void)?

    init(actions: [ToolbarAction], scrollDirection: UICollectionView.ScrollDirection = .vertical, finishOnSelection: Bool = true) {
        self.actions = actions
        self.scrollDirection = scrollDirection
        self.finishOnSelection = finishOnSelection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override var preferredContentSize: CGSize {
        get { return CGSize(width: 60, height: 60) }
        set {}
    }

}

extension ToolbarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ToolbarButtonCell

        cell.backgroundColor = .clear
        cell.itemImage = actions[indexPath.row].image
        cell.actionHandler = { [unowned self] in
            if self.finishOnSelection {
                self.dismiss(animated: true, completion: nil)
            }
            self.selectionHandler?(self.actions[indexPath.row])
        }

        return cell
    }
}

private extension ToolbarViewController {
    func setup() {
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.scrollDirection = scrollDirection

        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        view.addSubview(collectionView)
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

        collectionView.register(ToolbarButtonCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.dataSource = self
    }
}

extension AppToolbarAction: ToolbarAction {
    var image: UIImage? { return UIImage(named: "toolbar_\(rawValue)") }
}
