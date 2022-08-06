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

import LinkPresentation
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
    private lazy var layout = InfoCollectionLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)

    private let info: Selection
    private let isEmbeddedInNavigationController: Bool

    var selectionHandler: ((ObjectAction, UIView) -> Void)?

    private var actions: [ObjectAction]

    private var linkMetaData: AnyObject?

    init(info: Selection, isEmbeddedInNavigationController: Bool) {
        self.info = info
        self.isEmbeddedInNavigationController = isEmbeddedInNavigationController
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
        view.backgroundColor = isEmbeddedInNavigationController ? .darkBackground : .darkSecondaryBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        guard let urlString = info.webInfoURL, let url = URL(string: urlString), #available(iOS 13.0, *) else { return }

        let metaDataProvider = LPMetadataProvider()
        metaDataProvider.startFetchingMetadata(for: url) { [weak self] metaData, error in
            guard let data = metaData, error == nil else { return }
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.linkMetaData = data
                self.actions.removeAll(where: {
                    switch $0 {
                    case .web:
                        return true
                    default:
                        return false
                    }
                })
                self.collectionView.reloadData()
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            collectionView.collectionViewLayout.invalidateLayout()
        }
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

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        collectionView.backgroundColor = .clear
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).estimatedItemSize = CGSize(width: 1, height: 1)
        collectionView.register(BodyDescriptionCell.self, forCellWithReuseIdentifier: "Description")
        collectionView.register(BodyActionCell.self, forCellWithReuseIdentifier: "Action")
        if #available(iOS 13.0, *) {
            collectionView.register(LinkPreviewCell.self, forCellWithReuseIdentifier: "LinkPreview")
        }

        collectionView.dataSource = self
        collectionView.delegate = self
    }
}

extension InfoViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            if #available(iOS 13.0, *), linkMetaData is LPLinkMetadata {
                return 2
            }
            return 1
        }
        return actions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Description", for: indexPath) as! BodyDescriptionCell
                cell.update(with: BodyInfo(selection: info))
                return cell
            }
            if #available(iOS 13.0, *), let metaData = linkMetaData as? LPLinkMetadata {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LinkPreview", for: indexPath) as! LinkPreviewCell
                cell.setMetaData(metaData)
                return cell
            }
            fatalError()
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

class InfoCollectionLayout: UICollectionViewFlowLayout {
    private var attributesCache: [Int: UICollectionViewLayoutAttributes] = [:]

    // Only section 1 needs special handling
    private let twoColumnSection = 1

    override func prepare() {
        attributesCache = [:]

        guard let collectionView = self.collectionView else { super.prepare(); return }

        super.prepare()

        guard let dataSource = collectionView.dataSource else { return }
        let numberOfItems = dataSource.collectionView(collectionView, numberOfItemsInSection: twoColumnSection)
        var previousAttributes: UICollectionViewLayoutAttributes?
        for item in 0..<numberOfItems {
            let indexPath = IndexPath(item: item, section: twoColumnSection)
            guard let attributes = super.layoutAttributesForItem(at: indexPath) else { break }

            if item % 2 == 0 {
                previousAttributes = attributes
            } else {
                let height = max(previousAttributes!.size.height, attributes.size.height)
                previousAttributes!.size = CGSize(width: previousAttributes!.size.width, height: height)
                attributes.size = CGSize(width: attributes.size.width, height: height)
            }
            attributesCache[item] = attributes
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)

        var updatedAttributes: [UICollectionViewLayoutAttributes] = []
        attributes?.forEach({ attr in
            let ip = attr.indexPath
            if ip.section == twoColumnSection, let updatedAttr = attributesCache[ip.item] {
                updatedAttributes.append(updatedAttr)
            } else {
                updatedAttributes.append(attr)
            }
        })

        return updatedAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)

        var updatedAttributes = attributes
        if let ip = attributes?.indexPath, ip.section == twoColumnSection, let updated = attributesCache[ip.item] {
            updatedAttributes = updated
        }

        return updatedAttributes
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
        case .track:
            return CelestiaString("Track", comment: "")
        case .follow:
            return CelestiaString("Follow", comment: "")
        case .runDemo:
            return CelestiaString("Run Demo", comment: "")
        case .cancelScript:
            return CelestiaString("Cancel Script", comment: "")
        case .home:
            return CelestiaString("Home (Sol)", comment: "")
        case .stop:
            return CelestiaString("Stop", comment: "")
        case .reverseSpeed:
            return CelestiaString("Reverse Direction", comment: "")
        }
    }
}
