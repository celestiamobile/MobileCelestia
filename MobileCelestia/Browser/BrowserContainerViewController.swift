//
// BrowserContainerViewController.swift
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

class BrowserContainerViewController: UIViewController {
    #if targetEnvironment(macCatalyst)
    private var currentController: BrowserCoordinatorController?
    private var isToolbarConfigured = false
    private var selectedRootIndex: Int?
    #else
    private lazy var controller = UITabBarController()
    #endif
    private var isDataLoaded = false

    private let selected: (Selection) -> UIViewController

    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private lazy var rootItems: [(item: BrowserItem, image: UIImage)] = {
        return [
            (solBrowserRoot, #imageLiteral(resourceName: "browser_tab_sso")),
            (starBrowserRoot, #imageLiteral(resourceName: "browser_tab_star")),
            (dsoBrowserRoot, #imageLiteral(resourceName: "browser_tab_dso"))
        ].compactMap { (item, image) in
            if let item {
                return (item, image)
            } else {
                return nil
            }
        }
    }()

    init(selected: @escaping (Selection) -> UIViewController) {
        self.selected = selected
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

        setUp()

        let core = AppCore.shared
        activityIndicator.startAnimating()
        core.run { [weak self] core in
            createStaticBrowserItems()
            createDynamicBrowserItems()
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                self.rootItemsLoaded()
            }
        }
    }
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    static let back = NSToolbarItem.Identifier("space.celestia.MobileCelestia.back")
    static let root = NSToolbarItem.Identifier("space.celestia.MobileCelestia.root")
}

extension BrowserContainerViewController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.back, .root]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.back, .root]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .back:
            let image: UIImage?
            if #available(macCatalyst 14.0, *) {
                image = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(scale: .medium))
            } else {
                let isRTL = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft
                image = UIImage(systemName: isRTL ? "chevron.right" : "chevron.left", withConfiguration: UIImage.SymbolConfiguration(scale: .medium))
            }
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(scale: .medium)), style: .plain, target: self, action: #selector(back(_:)))
            let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            if #available(macCatalyst 14.0, *) {
                toolbarItem.isNavigational = true
            }
            return toolbarItem
        case .root:
            let itemGroup = NSToolbarItemGroup(itemIdentifier: itemIdentifier, titles: rootItems.map { $0.item.alternativeName ?? $0.item.name }, selectionMode: .selectOne, labels: nil, target: self, action: #selector(rootItemSelected(_:)))
            if selectedRootIndex == nil, rootItems.count > 0 {
                itemGroup.selectedIndex = 0
                rootItemSelected(itemGroup)
            }
            return itemGroup
        default:
            return nil
        }
    }
}

extension BrowserContainerViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setUpToolbarIfNeeded()
    }

    private func setUpToolbarIfNeeded() {
        guard !isToolbarConfigured, isDataLoaded else { return }
        guard let scene = view.window?.windowScene, let titlebar = scene.titlebar else { return }

        if #available(macCatalyst 14.0, *) {
            titlebar.toolbarStyle = .unifiedCompact
        }

        let toolbar = NSToolbar()
        toolbar.delegate = self
        if #available(macCatalyst 16.0, *) {
            toolbar.centeredItemIdentifiers = [.root]
        } else {
            toolbar.centeredItemIdentifier = .root
        }
        titlebar.toolbar = toolbar
        isToolbarConfigured = true
    }

    @objc private func back(_ sender: UIBarButtonItem) {
        currentController?.popViewController(animated: true)
    }

    @objc private func rootItemSelected(_ sender: NSToolbarItemGroup) {
        let handler = { [unowned self] (selection: Selection) -> UIViewController in
            return self.selected(selection)
        }
        currentController?.remove()
        let selectedItem = rootItems[sender.selectedIndex]
        let vc = BrowserCoordinatorController(item: selectedItem.item, image: selectedItem.image, selection: handler)
        vc.setNavigationBarHidden(true, animated: false)
        currentController = vc
        selectedRootIndex = sender.selectedIndex
        install(vc)
    }
}
#endif

private extension BrowserContainerViewController {
    func setUp() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func rootItemsLoaded() {
        activityIndicator.isHidden = true
        isDataLoaded = true
        #if targetEnvironment(macCatalyst)
        setUpToolbarIfNeeded()
        #else
        let handler = { [unowned self] (selection: Selection) -> UIViewController in
            return self.selected(selection)
        }
        install(controller)
        var allControllers = rootItems.map { (item, image) in
            return BrowserCoordinatorController(item: item, image: image, selection: handler)
        }
        controller.setViewControllers(allControllers, animated: false)
        #endif
    }
}
