//
// BottomControlViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

enum BottomControlAction {
    case toolbarAction(_ toolbarAction: ToolbarAction)
    case close

    var image: UIImage? {
        switch self {
        case .toolbarAction(let action):
            return action.image
        case .close:
            return #imageLiteral(resourceName: "bottom_control_hide")
        }
    }
}

class BottomControlViewController: UIViewController {
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    private let actions: [BottomControlAction]

    #if targetEnvironment(macCatalyst)
    private var touchBarActions: [ToolbarTouchBarAction]
    var touchBarActionConversionBlock: ((NSTouchBarItem.Identifier) -> ToolbarTouchBarAction?)?
    #endif

    private let finishOnSelection: Bool

    private var selectedAction: ToolbarAction?

    var selectionHandler: ((ToolbarAction) -> Void)?

    init(actions: [ToolbarAction], finishOnSelection: Bool = true) {
        self.actions = actions.map { BottomControlAction.toolbarAction($0) } + [.close]
        #if targetEnvironment(macCatalyst)
        self.touchBarActions = actions.compactMap { $0 as? ToolbarTouchBarAction }
        #endif
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
            return CGSize(width: CGFloat(60 * actions.count) + 16 + 8, height: 60 + 8 + 4)
        }
        set {}
    }

}

extension BottomControlViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ToolbarCell

        cell.backgroundColor = .clear
        let action = actions[indexPath.item]
        cell.itemImage = action.image

        switch action {
        case .toolbarAction(let action):
            cell.actionHandler = { [unowned self] in
                if self.finishOnSelection {
                    self.dismiss(animated: true, completion: nil)
                }
                self.selectionHandler?(action)
            }
        case .close:
            cell.actionHandler = { [unowned self] in
                self.dismiss(animated: true, completion: nil)
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

private extension BottomControlViewController {
    func setup() {
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.trailingAnchor.constraint(equalTo: view!.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: view!.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.scrollDirection = .horizontal

        layout.itemSize = CGSize(width: 60, height: 60)
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = 8
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let contentView = backgroundView.contentView
        contentView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            collectionView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            collectionView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = false

        collectionView.register(ToolbarImageButtonCell.self, forCellWithReuseIdentifier: "Cell")

        collectionView.dataSource = self
    }
}

#if targetEnvironment(macCatalyst)
extension BottomControlViewController: NSTouchBarDelegate {
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
