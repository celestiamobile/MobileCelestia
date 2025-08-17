// BottomControlViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import UIKit

struct OverflowItem {
    let title: String
    let action: BottomControlAction
}

enum BottomControlAction {
    enum CustomActionType {
        case showTimeSettings
    }

    case toolbarAction(_ toolbarAction: ToolbarAction)
    case custom(type: CustomActionType)
}

class BottomControlViewController: UIViewController {
    enum Item {
        case toolbarAction(_ toolbarAction: ToolbarAction)
        case custom(type: BottomControlAction.CustomActionType)
        case overflow

        init(_ action: BottomControlAction) {
            switch action {
            case let .toolbarAction(toolbarAction):
                self = .toolbarAction(toolbarAction)
            case let .custom(type):
                self = .custom(type: type)
            }
        }

        var image: UIImage? {
            switch self {
            case .toolbarAction(let action):
                return action.image
            case .overflow:
                return UIImage(systemName: "ellipsis")
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
            case .overflow:
                return CelestiaString("More actions", comment: "Button to show more actions to in the bottom toolbar")
            case let .custom(type):
                switch type {
                case .showTimeSettings:
                    return CelestiaString("Settings", comment: "")
                }
            }
        }
    }

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: BottomActionLayout())

    private let actions: [Item]
    private let overflowActions: [OverflowItem]

    #if targetEnvironment(macCatalyst)
    private var touchBarActions: [ToolbarTouchBarAction]
    var touchBarActionConversionBlock: ((NSTouchBarItem.Identifier) -> ToolbarTouchBarAction?)?
    #endif

    private var selectedAction: ToolbarAction?
    private var hideAction: (() -> Void)?

    var touchUpHandler: ((ToolbarAction, Bool) -> Void)?
    var touchDownHandler: ((ToolbarAction) -> Void)?
    var customActionHandler: ((BottomControlAction.CustomActionType) -> Void)?

    init(actions: [BottomControlAction], overflowActions: [OverflowItem] = [], hideAction: (() -> Void)?) {
        self.actions = actions.map { Item($0) } + [.overflow]
        self.overflowActions = overflowActions
        #if targetEnvironment(macCatalyst)
        self.touchBarActions = (actions + overflowActions.map { $0.action }).compactMap { action in
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

        setUp()
        preferredContentSize = calculatePreferredContentSize(traitCollection: view.traitCollection)

        if #available(iOS 17, *) {
            collectionView.registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { [weak self] (_: UICollectionView, _) in
                guard let self else { return }
                self.preferredContentSize = self.calculatePreferredContentSize(traitCollection: self.traitCollection)
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 17, *) {
        } else {
            if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
                preferredContentSize = calculatePreferredContentSize(traitCollection: traitCollection)
            }
        }
    }

    private func calculatePreferredContentSize(traitCollection: UITraitCollection) -> CGSize {
        let viewDimension = collectionView.scaledValue(for: GlobalConstants.bottomControlViewDimension * GlobalConstants.preferredUIElementScaling(for: traitCollection))
        return CGSize(
            width: CGFloat(actions.count) * viewDimension + GlobalConstants.bottomControlViewMarginHorizontal * 2 + GlobalConstants.pageMediumMarginHorizontal,
            height: viewDimension + GlobalConstants.bottomControlViewMarginVertical * 2 + GlobalConstants.pageMediumMarginVertical
        )
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! (ToolbarCell & UICollectionViewCell)

        cell.backgroundColor = .clear
        let action = actions[indexPath.item]
        cell.itemImage = action.image
        cell.itemAccessibilityLabel = action.accessibilityLabel

        switch action {
        case .toolbarAction(let action):
            cell.touchDownHandler = { [weak self] _ in
                guard let self else { return }
                self.touchDownHandler?(action)
            }
            cell.touchUpHandler = { [weak self] _, inside in
                guard let self else { return }
                self.touchUpHandler?(action, inside)
            }
            cell.menu = nil
        case .overflow:
            cell.touchUpHandler = nil
            cell.touchDownHandler = nil
            var menuItems = overflowActions.map { item in
                UIAction(title: item.title) { [weak self] _ in
                    guard let self else { return }
                    switch item.action {
                    case let .toolbarAction(action):
                        self.touchDownHandler?(action)
                        self.touchUpHandler?(action, true)
                    case let .custom(type):
                        self.customActionHandler?(type)
                    }
                }
            }
            menuItems.append(UIAction(title: CelestiaString("Close", comment: ""), handler: { [weak self] _ in
                guard let self else { return }
                self.hideAction?()
            }))
            cell.menu = UIMenu(children: menuItems)
        case let .custom(type):
            cell.touchUpHandler = { [weak self] _, inside in
                guard inside, let self else { return }
                self.customActionHandler?(type)
            }
            cell.touchDownHandler = nil
            cell.menu = nil
        }
        return cell
    }
}

private extension BottomControlViewController {
    func setUp() {
        if #available(iOS 15, *) {
            view.maximumContentSizeCategory = .extraExtraExtraLarge
        }

        let effect: UIVisualEffect
        if #available(iOS 26, *) {
            effect = UIGlassEffect(style: .regular)
        } else {
            effect = UIBlurEffect(style: .regular)
        }
        let backgroundView = UIVisualEffectView(effect: effect)
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
        let scaling = GlobalConstants.preferredUIElementScaling(for: collectionView.traitCollection)
        itemSize = CGSize(width: collectionView.scaledValue(for: baseItemSize.width * scaling), height: collectionView.scaledValue(for: baseItemSize.height * scaling))
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
