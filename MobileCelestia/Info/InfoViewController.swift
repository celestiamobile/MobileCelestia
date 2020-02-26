//
//  ViewController.swift
//  TestViewController
//
//  Created by Li Linfeng on 2020/2/24.
//  Copyright © 2020 Li Linfeng. All rights reserved.
//

import UIKit

enum ObjectAction {
    case select
    case wrapped(action: CelestiaAction)
}

private extension ObjectAction {
    static var allCases: [ObjectAction] {
        return [.select] + CelestiaAction.allCases.map { ObjectAction.wrapped(action: $0) }
    }
}

final class InfoViewController: UIViewController {
    private lazy var layout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)

    private let info: BodyInfo

    var selectionHandler: ((ObjectAction?) -> Void)?

    init(info: BodyInfo) {
        self.info = info
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
}

private extension InfoViewController {
    func setup() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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

        collectionView.backgroundColor = .clear
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).estimatedItemSize = CGSize(width: 1, height: 1)
        collectionView.register(BodyDescriptionCell.self, forCellWithReuseIdentifier: "Description")
        collectionView.register(BodyActionCell.self, forCellWithReuseIdentifier: "Action")

        collectionView.dataSource = self
        collectionView.delegate = self
    }
}

extension InfoViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        return ObjectAction.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Description", for: indexPath) as! BodyDescriptionCell
            cell.update(with: info)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Action", for: indexPath) as! BodyActionCell
        let action = ObjectAction.allCases[indexPath.item]
        cell.title = action.description
        cell.actionHandler = { [weak self] in
            guard let self = self else { return }
            self.selectionHandler?(action)
        }
        return cell
    }

}

private extension ObjectAction {
    var description: String {
        switch self {
        case .select:
            return CelestiaString("Select", comment: "")
        case .wrapped(let action):
            return action.description
        }
    }
}

private extension CelestiaAction {
    var description: String {
        switch self {
        case .goto:
            return CelestiaString("Go", comment: "")
        case .center:
            return CelestiaString("Center", comment: "")
        case .playpause:
            return CelestiaString("Resume/Pause", comment: "")
        case .backward:
            return CelestiaString("Backward", comment: "")
        case .forward:
            return CelestiaString("Forward", comment: "")
        case .currentTime:
            return CelestiaString("Current Time", comment: "")
        case .syncOrbit:
            return CelestiaString("Sync Orbit", comment: "")
        case .lock:
            return CelestiaString("Lock", comment: "")
        case .chase:
            return CelestiaString("Chase", comment: "")
        case .follow:
            return CelestiaString("Follow", comment: "")
        }
    }
}
