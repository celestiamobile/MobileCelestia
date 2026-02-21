// TutorialViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import UIKit

enum TutorialAction {
    case runDemo
}

class TutorialViewController: UICollectionViewController {
    private struct TutorialDescriptionItem {
        let image: UIImage?
        let text: String
    }

    private struct TutorialActionItem {
        let title: String
        let object: TutorialAction
    }

    private struct TutorialURLItem {
        let title: String
        let url: URL
    }

    private enum TutorialItem {
        case description(item: TutorialDescriptionItem)
        case action(item: TutorialActionItem)
        case url(url: TutorialURLItem)
    }

    #if !targetEnvironment(macCatalyst)
    private lazy var tutorialDescriptionItems = [
        TutorialDescriptionItem(image: assetProvider.image(for: .tutorialSwitchMode),
                                text: CelestiaString("Tap the mode button on the sidebar to switch between object mode and camera mode.", comment: "")),
        TutorialDescriptionItem(image: UIImage(systemName: "cube"),
                                text: CelestiaString("In object mode, drag to rotate around an object.\n\nPinch to zoom in/out on an object.", comment: "")),
        TutorialDescriptionItem(image: UIImage(systemName: "video"),
                                text: CelestiaString("In camera mode, drag to move field of view.\n\nPinch to zoom in/out field of view.", comment: "")),
    ]
    #else
    private lazy var tutorialDescriptionItems: [TutorialDescriptionItem] = []
    #endif

    private lazy var tutorialActionItems = [
        TutorialActionItem(title: CelestiaString("Run Demo", comment: ""), object: .runDemo),
    ]

    private lazy var urlItems = [
        TutorialURLItem(title: CelestiaString("Mouse/Keyboard Controls", comment: "Guide to control Celestia with a mouse/keyboard"), url: URL(string: "celestia://article/BE1B5023-46B6-1F10-F15F-3B3F02F30300")!),
        TutorialURLItem(title: CelestiaString("Use Add-ons and Scripts", comment: "URL for Use Add-ons and Scripts wiki"), url: URL(string: "celestia://article/D1A96BFA-00BB-0089-F361-10DD886C8A4F")!),
        TutorialURLItem(title: CelestiaString("Scripts and URLs", comment: "URL for Scripts and URLs wiki"), url: URL(string: "celestia://article/A0AB3F01-E616-3C49-0934-0583D803E9D0")!),
    ]

    private lazy var tutorialItems: [[TutorialItem]] = [
        self.tutorialDescriptionItems.map { TutorialItem.description(item: $0) },
        self.urlItems.map { TutorialItem.url(url: $0) },
        self.tutorialActionItems.map { TutorialItem.action(item: $0) }
    ]

    private let actionHandler: ((TutorialAction) -> Void)?
    private let urlHandler: ((URL) -> Void)?
    private let assetProvider: AssetProvider

    init(assetProvider: AssetProvider, actionHandler: ((TutorialAction) -> Void)?, urlHandler: ((URL) -> Void)?) {
        self.assetProvider = assetProvider
        self.actionHandler = actionHandler
        self.urlHandler = urlHandler
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = false
        configuration.backgroundColor = .clear
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: configuration))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension TutorialViewController {
    func setup() {
        collectionView.register(TutorialDescriptionCell.self, forCellWithReuseIdentifier: "Description")
        collectionView.register(TutorialActionCell.self, forCellWithReuseIdentifier: "Action")
        collectionView.register(TutorialActionCell.self, forCellWithReuseIdentifier: "URL")
    }
}

extension TutorialViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return tutorialItems.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tutorialItems[section].count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = tutorialItems[indexPath.section][indexPath.row]
        switch item {
        case .description(let desc):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Description", for: indexPath) as! TutorialDescriptionCell
            cell.title = desc.text
            cell.img = desc.image
            return cell
        case .action(let action):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Action", for: indexPath) as! TutorialActionCell
            cell.title = action.title
            cell.actionHandler = { [unowned self] in
                self.actionHandler?(action.object)
            }
            return cell
        case .url(let url):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Action", for: indexPath) as! TutorialActionCell
            cell.title = url.title
            cell.actionHandler = { [unowned self] in
                self.urlHandler?(url.url)
            }
            return cell
        }
    }
}
