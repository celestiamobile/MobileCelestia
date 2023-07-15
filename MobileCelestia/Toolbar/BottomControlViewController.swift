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

import CelestiaUI
import UIKit

enum BottomControlAction {
    enum CustomActionType {
        case showTimeSettings
    }

    case toolbarAction(_ toolbarAction: ToolbarAction)
    case groupedActions(accessibilityLabel: String, actions: [ToolbarAction])
    case close
    case custom(type: CustomActionType)

    var image: UIImage? {
        switch self {
        case .toolbarAction(let action):
            return action.image
        case .groupedActions:
            return UIImage(systemName: "ellipsis")
        case .close:
            return UIImage(systemName: "chevron.down")?.withConfiguration(UIImage.SymbolConfiguration(weight: .black))
        case let .custom(type):
            switch type {
            case .showTimeSettings:
                return UIImage(systemName: "gear")?.withConfiguration(UIImage.SymbolConfiguration(weight: .bold))
            }
        }
    }

    var accessibilityLabel: String? {
        switch self {
        case .toolbarAction(let action):
            return action.title
        case .groupedActions(let accessibilityLabel, _):
            return accessibilityLabel
        case .close:
            return CelestiaString("Close", comment: "")
        case let .custom(type):
            switch type {
            case .showTimeSettings:
                return CelestiaString("Settings", comment: "")
            }
        }
    }
}

class BottomControlViewController: UIViewController {
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: BottomActionLayout())

    private let actions: [BottomControlAction]

    #if targetEnvironment(macCatalyst)
    private var touchBarActions: [ToolbarTouchBarAction]
    var touchBarActionConversionBlock: ((NSTouchBarItem.Identifier) -> ToolbarTouchBarAction?)?
    #endif

    private var selectedAction: ToolbarAction?
    private var hideAction: (() -> Void)?

    var touchUpHandler: ((ToolbarAction, Bool) -> Void)?
    var touchDownHandler: ((ToolbarAction) -> Void)?
    var customActionHandler: ((BottomControlAction.CustomActionType) -> Void)?

    init(actions: [BottomControlAction], hideAction: (() -> Void)?) {
        self.actions = actions + [.close]
        #if targetEnvironment(macCatalyst)
        self.touchBarActions = actions.compactMap { action in
            if case .toolbarAction(let ac) = action, let ttba = ac as? ToolbarTouchBarAction {
                return ttba
            }
            return nil
        }
        #endif
        self.hideAction = hideAction
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
            let scaling = view.textScaling * GlobalConstants.preferredUIElementScaling(for: view.traitCollection)
            return CGSize(
                width: GlobalConstants.bottomControlViewDimension * CGFloat(actions.count) * scaling + GlobalConstants.bottomControlViewMarginHorizontal * 2 + GlobalConstants.pageMediumMarginHorizontal,
                height: (GlobalConstants.bottomControlViewDimension * scaling + GlobalConstants.bottomControlViewMarginVertical * 2 + GlobalConstants.pageMediumMarginVertical).rounded(.up)
            )
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
        cell.itemAccessibilityLabel = action.accessibilityLabel

        switch action {
        case .toolbarAction(let action):
            cell.touchDownHandler = { [unowned self] _ in
                self.touchDownHandler?(action)
            }
            cell.touchUpHandler = { [unowned self] _, inside in
                self.touchUpHandler?(action, inside)
            }
        case .groupedActions(_, let actions):
            cell.touchUpHandler = { [unowned self] button, inside in
                guard inside else { return }
                self.showSelection(nil, options: actions.map { $0.title ?? "" }, source: .view(view: button, sourceRect: nil)) { [unowned self] selectedIndex in
                    if let index = selectedIndex {
                        let item = actions[index]
                        self.touchDownHandler?(item)
                        self.touchUpHandler?(item, true)
                    }
                }
            }
            cell.touchDownHandler = nil
        case .close:
            cell.touchUpHandler = { [unowned self] _, inside in
                guard inside else { return }
                self.hideAction?()
                self.hideAction = nil
            }
            cell.touchDownHandler = nil
        case let .custom(type):
            cell.touchUpHandler = { [unowned self] _, inside in
                guard inside else { return }
                self.customActionHandler?(type)
            }
            cell.touchDownHandler = nil
        }
        return cell
    }
}

private extension BottomControlViewController {
    func setup() {
        if #available(iOS 15, *) {
            view.maximumContentSizeCategory = .extraExtraExtraLarge
        }

        let style: UIBlurEffect.Style = .regular
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.trailingAnchor.constraint(equalTo: view!.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: view!.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -GlobalConstants.pageMediumMarginVertical)
        ])

        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = GlobalConstants.bottomControlContainerCornerRadius
        backgroundView.layer.cornerCurve = .continuous

        let contentView = backgroundView.contentView
        contentView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
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
        touchUpHandler?(action, true)
    }

    @objc private func requestClose() {
        hideAction?()
        hideAction = nil
    }
}
#endif

class BottomActionLayout: UICollectionViewFlowLayout {
    private let baseItemSize = CGSize(width: GlobalConstants.bottomControlViewDimension, height: GlobalConstants.bottomControlViewDimension)

    override func prepare() {
        defer { super.prepare() }
        guard let collectionView = self.collectionView else { return }
        let scaling = GlobalConstants.preferredUIElementScaling(for: collectionView.traitCollection) * collectionView.textScaling
        itemSize = baseItemSize.applying(CGAffineTransform(scaleX: scaling, y: scaling))
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        sectionInset = UIEdgeInsets(
            top: GlobalConstants.bottomControlViewMarginVertical,
            left: GlobalConstants.bottomControlViewMarginHorizontal,
            bottom: GlobalConstants.bottomControlViewMarginVertical,
            right: GlobalConstants.bottomControlViewMarginHorizontal
        )
        scrollDirection = .horizontal
        super.prepare()
    }
}
