//
// ToolbarAwareViewController.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public protocol ToolbarAwareViewController: UIViewController {
    #if targetEnvironment(macCatalyst)
    func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier]
    func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem?
    #endif
}

#if targetEnvironment(macCatalyst)
extension UIViewController {
    func updateToolbarIfNeeded() {
        nearestToolbarContainerViewController?.updateToolbar(for: self)
    }

    private var nearestToolbarContainerViewController: ToolbarContainerViewController? {
        var current: UIViewController? = self
        while let viewController = current {
            if let container = viewController as? ToolbarContainerViewController {
                return container
            }
            current = viewController.parent
        }
        return nil
    }
}
#endif

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: ToolbarNavigationContainerController.self).bundleIdentifier!
    fileprivate static let back = NSToolbarItem.Identifier.init("\(prefix).back")
}
#endif

public protocol ToolbarContainerViewController: UIViewController {
    #if targetEnvironment(macCatalyst)
    var nsToolbar: NSToolbar? { get set }
    func updateToolbar(for viewController: UIViewController)
    #endif
}

open class ToolbarNavigationContainerController: UIViewController, ToolbarContainerViewController {
    private let navigation: UINavigationController
    private var titleObservation: NSKeyValueObservation?

    public var topViewController: UIViewController? {
        return navigation.topViewController
    }

    public init(rootViewController: UIViewController) {
        #if targetEnvironment(macCatalyst)
        let vc = ToolbarAwareNavigationController(rootViewController: rootViewController)
        navigation = vc
        #else
        navigation = UINavigationController(rootViewController: rootViewController)
        #endif
        super.init(nibName: nil, bundle: nil)
        install(navigation)
        #if targetEnvironment(macCatalyst)
        vc.delegate = self
        #endif
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        navigation.setViewControllers(viewControllers, animated: animated)
    }

    public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        return navigation.pushViewController(viewController, animated: animated)
    }

    @discardableResult public func popViewController(animated: Bool) -> UIViewController? {
        return navigation.popViewController(animated: animated)
    }

    @discardableResult public func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        navigation.popToViewController(viewController, animated: animated)
    }

    @discardableResult public func popToRootViewController(animated: Bool) -> [UIViewController]? {
        navigation.popToRootViewController(animated: animated)
    }

    #if targetEnvironment(macCatalyst)
    private var currentToolbarHost: ToolbarAwareViewController?
    private var currentToolbarItemIdentifiers: [NSToolbarItem.Identifier] = []

    private lazy var backToolbarItem = NSToolbarItem(backItemIdentifier: .back, target: self, action: #selector(goBack))

    public var nsToolbar: NSToolbar? {
        didSet {
            toolbarDidUpdate(oldValue)
        }
    }

    @available(iOS 16.0, *)
    public enum FallbackStyle {
        case none
        case sidebar
        case content
        case supplementary
    }

    @available(iOS 16.0, *)
    open var fallbackStyle: FallbackStyle {
        return .none
    }

    private func toolbarDidUpdate(_ oldToolbar: NSToolbar?) {
        guard oldToolbar != nsToolbar else { return }
        // Remvoe the old items
        if let oldToolbar {
            while !oldToolbar.items.isEmpty {
                oldToolbar.removeItem(at: 0)
            }
        }
        navigation.setNavigationBarHidden(nsToolbar != nil, animated: false)
        nsToolbar?.delegate = self
        nsToolbar?.displayMode = .iconOnly
        updateToolbar()
    }

    @objc private func goBack() {
        popViewController(animated: true)
    }

    public func updateToolbar(for viewController: UIViewController) {
        guard viewController == topViewController else { return }
        _updateToolbar(for: viewController)
    }

    public func _updateToolbar(for viewController: UIViewController) {
        if let vc = viewController as? ToolbarAwareViewController {
            currentToolbarItemIdentifiers = vc.supportedToolbarItemIdentifiers(for: self)
        } else {
            currentToolbarItemIdentifiers = []
        }
        updateToolbar()
    }

    private func updateToolbar() {
        guard let nsToolbar else { return }

        // Remove old items
        while !nsToolbar.items.isEmpty {
            nsToolbar.removeItem(at: 0)
        }

        let itemsToInsert: [NSToolbarItem.Identifier]
        if navigation.viewControllers.count > 1 {
            itemsToInsert = [.back] + currentToolbarItemIdentifiers
        } else {
            itemsToInsert = currentToolbarItemIdentifiers
        }

        for itemToInsert in itemsToInsert.reversed() {
            nsToolbar.insertItem(withItemIdentifier: itemToInsert, at: 0)
        }
    }
    #endif
}

#if targetEnvironment(macCatalyst)
protocol ToolbarAwareNavigationControllerDelegate: UINavigationControllerDelegate {
    @available(iOS 16.0, *)
    func fallbackStyleForNavigationController(_ navigationController: UINavigationController) -> ToolbarNavigationContainerController.FallbackStyle
}

private class ToolbarAwareNavigationController: UINavigationController {}

@available(iOS 16.0, *)
extension ToolbarAwareNavigationController: UINavigationBarDelegate {
    public func navigationBarNSToolbarSection(_ navigationBar: UINavigationBar) -> UINavigationBar.NSToolbarSection {
        if let delegate = self.delegate as? ToolbarAwareNavigationControllerDelegate {
            return UINavigationBar.NSToolbarSection(style: delegate.fallbackStyleForNavigationController(self))
        }
        return .none
    }
}

extension ToolbarNavigationContainerController: ToolbarAwareNavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        view.window?.windowScene?.title = viewController.title
        titleObservation?.invalidate()
        titleObservation = viewController.observe(\.title) { [weak self] viewController, _ in
            guard let self else { return }
            self.view.window?.windowScene?.title = viewController.title
        }
        currentToolbarHost = viewController as? ToolbarAwareViewController
        _updateToolbar(for: viewController)
    }

    @available(iOS 16.0, *)
    func fallbackStyleForNavigationController(_ navigationController: UINavigationController) -> FallbackStyle {
        if nsToolbar == nil {
            return .none
        }
        return fallbackStyle
    }
}

extension ToolbarNavigationContainerController: NSToolbarDelegate {
    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.back] + currentToolbarItemIdentifiers
    }

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        if navigation.viewControllers.count > 1 {
            return [.back] + currentToolbarItemIdentifiers
        }
        return currentToolbarItemIdentifiers
    }

    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == .back {
            return backToolbarItem
        }
        return currentToolbarHost?.toolbarContainerViewController(self, itemForItemIdentifier: itemIdentifier)
    }
}

@available(iOS 16.0, *)
extension UINavigationBar.NSToolbarSection {
    init(style: ToolbarNavigationContainerController.FallbackStyle) {
        switch style {
        case .none:
            self = .none
        case .sidebar:
            self = .sidebar
        case .content:
            self = .content
        case .supplementary:
            self = .supplementary
        }
    }
}

extension NSToolbarItem {
    convenience init(itemIdentifier: NSToolbarItem.Identifier, buttonTitle: String, target: Any, action: Selector) {
        self.init(itemIdentifier: itemIdentifier)
        let buttonClass = NSClassFromString("NSButton") as! NSObject.Type
        typealias ButtonCreationMethod = @convention(c)
        (NSObject.Type, Selector, NSString, Any, Selector) -> NSObject
        let selector = NSSelectorFromString("buttonWithTitle:target:action:")
        let methodIMP = buttonClass.method(for: selector)
        let method = unsafeBitCast(methodIMP, to: ButtonCreationMethod.self)
        let button = method(buttonClass, selector, buttonTitle as NSString, target, action)
        button.setValue(11, forKey: "bezelStyle") // textureRounded
        setValue(button, forKey: "view")
    }

    convenience init(backItemIdentifier: NSToolbarItem.Identifier, target: Any, action: Selector) {
        self.init(itemIdentifier: backItemIdentifier)
        let imageClass = NSClassFromString("NSImage") as! NSObject.Type
        let image = imageClass.perform(NSSelectorFromString("imageNamed:"), with: "NSGoBackTemplate").takeUnretainedValue()
        let buttonClass = NSClassFromString("NSButton") as! NSObject.Type
        typealias ButtonCreationMethod = @convention(c)
        (NSObject.Type, Selector, AnyObject, Any, Selector) -> NSObject
        let selector = NSSelectorFromString("buttonWithImage:target:action:")
        let methodIMP = buttonClass.method(for: selector)
        let method = unsafeBitCast(methodIMP, to: ButtonCreationMethod.self)
        let button = method(buttonClass, selector, image, target, action)
        button.setValue(11, forKey: "bezelStyle") // textureRounded
        setValue(button, forKey: "view")
        if #available(macCatalyst 14.0, *) {
            isNavigational = true
        }
    }

    convenience init(searchItemIdentifier: NSToolbarItem.Identifier, target: Any, action: Selector) {
        self.init(itemIdentifier: searchItemIdentifier)
        let searchFieldClass = NSClassFromString("NSSearchField") as! NSObject.Type
        let searchField = searchFieldClass.init()
        searchField.perform(NSSelectorFromString("setTarget:"), with: target)
        let selector = NSSelectorFromString("setAction:")
        typealias SetActionMethod = @convention(c) (NSObject, Selector, Selector) -> Void
        let methodIMP = searchFieldClass.instanceMethod(for: selector)
        let method = unsafeBitCast(methodIMP, to: SetActionMethod.self)
        method(searchField, selector, action)
        setValue(searchField, forKey: "view")
    }
}
#endif
