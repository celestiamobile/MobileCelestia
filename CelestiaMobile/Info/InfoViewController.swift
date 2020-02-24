//
//  ViewController.swift
//  TestViewController
//
//  Created by Li Linfeng on 2020/2/24.
//  Copyright © 2020 Li Linfeng. All rights reserved.
//

import UIKit

final class InfoViewController: UIViewController {
    private lazy var layout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)

    var selectionHandler: ((CelestiaAction?) -> Void)?
    private var selectedAction: CelestiaAction?

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        selectionHandler?(selectedAction)
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
        return CelestiaAction.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Description", for: indexPath)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Action", for: indexPath) as! BodyActionCell
        let action = CelestiaAction.allCases[indexPath.item]
        cell.title = action.description
        cell.actionHandler = { [weak self] in
            guard let self = self else { return }
            self.selectedAction = action
            self.dismiss(animated: true, completion: nil)
        }
        return cell
    }

}

private extension CelestiaAction {
    var description: String {
        // TODO: replace with call to gettext
        switch self {
        case .goto:
            return NSLocalizedString("Goto", comment: "")
        case .center:
            return NSLocalizedString("Center", comment: "")
        }
    }
}
