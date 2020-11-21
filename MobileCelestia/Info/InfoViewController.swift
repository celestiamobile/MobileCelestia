//
// InfoViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

import CelestiaCore

enum ObjectAction {
    case select
    case web(url: URL)
    case wrapped(action: CelestiaAction)
    case subsystem
    case alternateSurfaces
    case mark
}

private extension ObjectAction {
    static var allCases: [ObjectAction] {
        return [.select] + CelestiaAction.allCases.map { ObjectAction.wrapped(action: $0) }
    }
}

final class InfoViewController: UIViewController {
    private lazy var layout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)

    private let info: CelestiaSelection

    var selectionHandler: ((ObjectAction, UIView) -> Void)?

    private var actions: [ObjectAction]

    init(info: CelestiaSelection) {
        self.info = info
        var actions = ObjectAction.allCases
        if let urlString = info.webInfoURL, let url = URL(string: urlString) {
            actions.append(.web(url: url))
        }
        if let surfaces = info.body?.alternateSurfaceNames, surfaces.count > 0 {
            actions.append(.alternateSurfaces)
        }
        actions.append(.subsystem)
        actions.append(.mark)
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkSecondaryBackground
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
        return actions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Description", for: indexPath) as! BodyDescriptionCell
            cell.update(with: BodyInfo(selection: info))
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Action", for: indexPath) as! BodyActionCell
        let action = actions[indexPath.item]
        cell.title = action.description
        cell.actionHandler = { [unowned self] view in
            self.selectionHandler?(action, view)
        }
        return cell
    }

}

private extension ObjectAction {
    var description: String {
        switch self {
        case .select:
            return CelestiaString("Select", comment: "")
        case .web(_):
            return CelestiaString("Web Info", comment: "")
        case .wrapped(let action):
            return action.description
        case .subsystem:
            return CelestiaString("Subsystem", comment: "")
        case .alternateSurfaces:
            return CelestiaString("Alternate Surfaces", comment: "")
        case .mark:
            return CelestiaString("Mark", comment: "")
        }
    }
}

extension CelestiaAction {
    var description: String {
        switch self {
        case .goTo:
            return CelestiaString("Go", comment: "")
        case .goToSurface:
            return CelestiaString("Land", comment: "")
        case .center:
            return CelestiaString("Center", comment: "")
        case .playpause:
            return CelestiaString("Resume/Pause", comment: "")
        case .slower:
            return CelestiaString("Slower", comment: "")
        case .faster:
            return CelestiaString("Faster", comment: "")
        case .reverse:
            return CelestiaString("Reverse Time", comment: "")
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
        case .runDemo:
            return CelestiaString("Run Demo", comment: "")
        case .cancelScript:
            return CelestiaString("Cancel Script", comment: "")
        case .home:
            return CelestiaString("Home (Sol)", comment: "")
        }
    }
}
