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
    case groupedActions(_ actions: [ToolbarAction])
    case close

    var image: UIImage? {
        switch self {
        case .toolbarAction(let action):
            return action.image
        case .groupedActions:
            return UIImage(systemName: "ellipsis")
        case .close:
            return UIImage(systemName: "chevron.down")?.withConfiguration(UIImage.SymbolConfiguration(weight: .black))
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

    private let finishOnSelection: Bool

    private var selectedAction: ToolbarAction?

    var touchUpHandler: ((ToolbarAction, Bool) -> Void)?
    var touchDownHandler: ((ToolbarAction) -> Void)?

    init(actions: [BottomControlAction], finishOnSelection: Bool = true) {
        self.actions = actions + [.close]
        #if targetEnvironment(macCatalyst)
        self.touchBarActions = actions.compactMap { action in
            if case .toolbarAction(let ac) = action, let ttba = ac as? ToolbarTouchBarAction {
                return ttba
            }
            return nil
        }
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
            let scaling = view.textScaling
            return CGSize(width: CGFloat(60 * actions.count) * scaling + 16 + 8, height: (60 * scaling + 8 + 4).rounded(.up))
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
            cell.touchDownHandler = { [unowned self] _ in
                self.touchDownHandler?(action)
            }
            cell.touchUpHandler = { [unowned self] _, inside in
                if inside, self.finishOnSelection {
                    self.dismiss(animated: true, completion: nil)
                }
                self.touchUpHandler?(action, inside)
            }
        case .groupedActions(let actions):
            cell.touchUpHandler = { [unowned self] button, inside in
                guard inside else { return }
                self.showSelection(nil, options: actions.map { $0.title ?? "" }, sourceView: button, sourceRect: button.bounds) { [unowned self] selectedIndex in
                    if let index = selectedIndex {
                        if self.finishOnSelection {
                            self.dismiss(animated: true, completion: nil)
                        }
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
                self.dismiss(animated: true, completion: nil)
            }
            cell.touchDownHandler = nil
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
        view.maximumContentSizeCategory = .extraExtraExtraLarge

        let style: UIBlurEffect.Style
        if #available(iOS 13.0, *) {
            style = .regular
        } else {
            style = .dark
        }
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.trailingAnchor.constraint(equalTo: view!.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: view!.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = 8

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
        touchUpHandler?(action, true)
    }

    @objc private func requestClose() {
        dismiss(animated: true, completion: nil)
    }
}
#endif

class BottomActionLayout: UICollectionViewFlowLayout {
    private let baseItemSize = CGSize(width: 60, height: 60)

    override func prepare() {
        let scaling = collectionView?.textScaling ?? 1
        itemSize = baseItemSize.applying(CGAffineTransform(scaleX: scaling, y: scaling))
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        sectionInset = .zero
        scrollDirection = .horizontal
        super.prepare()
    }
}
