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
    func insertSpaceBeforeToolbarItems(for toolbarContainerViewController: ToolbarContainerViewController) -> Bool
    func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier]
    func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem?
    #endif
}

#if targetEnvironment(macCatalyst)
public extension ToolbarAwareViewController {
    func insertSpaceBeforeToolbarItems(for toolbarContainerViewController: ToolbarContainerViewController) -> Bool {
        return true
    }
}
#endif

#if targetEnvironment(macCatalyst)
@available(iOS 16, *)
public enum ToolbarFallbackStyle {
    case none
    case sidebar
    case content
    case supplementary
}
#endif

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
    #if targetEnvironment(macCatalyst)
    private var titleObservation: NSKeyValueObservation?
    #endif

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
    private var currentToolbarItemIdentifiers: [NSToolbarItem.Identifier] = []

    private lazy var backToolbarItem = NSToolbarItem(backItemIdentifier: .back, target: self, action: #selector(goBack))

    public var nsToolbar: NSToolbar? {
        didSet {
            toolbarDidUpdate(oldValue)
        }
    }

    @available(iOS 16, *)
    open var fallbackStyle: ToolbarFallbackStyle {
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
            var items = [NSToolbarItem.Identifier]()
            if vc.insertSpaceBeforeToolbarItems(for: self) {
                items.append(.flexibleSpace)
            }
            items += vc.supportedToolbarItemIdentifiers(for: self)
            currentToolbarItemIdentifiers = items
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

        let itemsToInsert = toolbarDefaultItemIdentifiers(nsToolbar)
        for itemToInsert in itemsToInsert.reversed() {
            nsToolbar.insertItem(withItemIdentifier: itemToInsert, at: 0)
        }
    }
    #endif
}

#if targetEnvironment(macCatalyst)
protocol ToolbarAwareNavigationControllerDelegate: UINavigationControllerDelegate {
    @available(iOS 16, *)
    func fallbackStyleForNavigationController(_ navigationController: UINavigationController) -> ToolbarFallbackStyle
}

private class ToolbarAwareNavigationController: UINavigationController {}

@available(iOS 16, *)
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
        _updateToolbar(for: viewController)
    }

    @available(iOS 16, *)
    func fallbackStyleForNavigationController(_ navigationController: UINavigationController) -> ToolbarFallbackStyle {
        if nsToolbar == nil {
            return fallbackStyle
        }
        return .none
    }
}

extension ToolbarNavigationContainerController: NSToolbarDelegate {
    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.back] + currentToolbarItemIdentifiers
    }

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        var items = [NSToolbarItem.Identifier]()
        if navigation.viewControllers.count > 1 {
            items.append(.back)
        }
        items += currentToolbarItemIdentifiers
        return items
    }

    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == .back {
            return backToolbarItem
        }
        return (topViewController as? ToolbarAwareViewController)?.toolbarContainerViewController(self, itemForItemIdentifier: itemIdentifier)
    }
}

@available(iOS 16, *)
extension UINavigationBar.NSToolbarSection {
    init(style: ToolbarFallbackStyle) {
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

@objc private final class SearchToolbarItem: NSToolbarItem {
    private static var searchItemClassPrepared = false
    private let textChangeHandler: (String?) -> Void
    private let returnHandler: (String?) -> Void
    private let searchStartHandler: () -> Void
    private let searchEndHandler: () -> Void

    private let searchField: NSObject

    init(itemIdentifier: NSToolbarItem.Identifier, currentText: String?, textChangeHandler: @escaping (String?) -> Void, returnHandler: @escaping (String?) -> Void, searchStartHandler: @escaping () -> Void, searchEndHandler: @escaping () -> Void) {
        if !Self.searchItemClassPrepared {
            if let delegateProtocol = objc_getProtocol("NSSearchFieldDelegate") {
                class_addProtocol(SearchToolbarItem.self, delegateProtocol)
                Self.searchItemClassPrepared = SearchToolbarItem.conforms(to: delegateProtocol)
            }
        }

        let searchFieldClass = NSClassFromString("NSSearchField") as! NSObject.Type
        searchField = searchFieldClass.init()
        if let currentText {
            searchField.setValue(currentText, forKey: "stringValue")
        }
        self.textChangeHandler = textChangeHandler
        self.returnHandler = returnHandler
        self.searchStartHandler = searchStartHandler
        self.searchEndHandler = searchEndHandler
        super.init(itemIdentifier: itemIdentifier)
        searchField.perform(NSSelectorFromString("setTarget:"), with: self)
        if Self.searchItemClassPrepared {
            let selector = NSSelectorFromString("setDelegate:")
            typealias SetDelegateMethod = @convention(c) (NSObject, Selector, NSObject?) -> Void
            let methodIMP = searchFieldClass.instanceMethod(for: selector)
            let method = unsafeBitCast(methodIMP, to: SetDelegateMethod.self)
            method(searchField, selector, self)
        }
        let selector = NSSelectorFromString("setAction:")
        typealias SetActionMethod = @convention(c) (NSObject, Selector, Selector) -> Void
        let methodIMP = searchFieldClass.instanceMethod(for: selector)
        let method = unsafeBitCast(methodIMP, to: SetActionMethod.self)
        method(searchField, selector, #selector(textChanged(_:)))
        setValue(searchField, forKey: "view")
    }

    @objc private func textChanged(_ sender: NSObject) {
        let value = searchField.value(forKey: "stringValue") as? String
        textChangeHandler(value)
    }

    @objc(control:textView:doCommandBySelector:) func control(_ control: NSObject, textView: NSObject, doCommandBySelector selector: Selector) -> Bool {
        if selector == NSSelectorFromString("insertNewline:") {
            let value = searchField.value(forKey: "stringValue") as? String
            returnHandler(value)
            return true
        }
        return false
    }

    @objc(searchFieldDidStartSearching:) func searchFieldDidStartSearching(_ sender: NSObject) {
        searchStartHandler()
    }

    @objc(searchFieldDidEndSearching:) func searchFieldDidEndSearching(_ sender: NSObject) {
        searchEndHandler()
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
        toolTip = buttonTitle
        label = buttonTitle
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
        toolTip = CelestiaString("Back", comment: "Undo an operation")
        isNavigational = true
    }

    convenience init(addItemIdentifier: NSToolbarItem.Identifier, target: Any, action: Selector) {
        self.init(itemIdentifier: addItemIdentifier)
        let imageClass = NSClassFromString("NSImage") as! NSObject.Type
        let image = imageClass.perform(NSSelectorFromString("imageNamed:"), with: "NSAddTemplate").takeUnretainedValue()
        let buttonClass = NSClassFromString("NSButton") as! NSObject.Type
        typealias ButtonCreationMethod = @convention(c)
        (NSObject.Type, Selector, AnyObject, Any, Selector) -> NSObject
        let selector = NSSelectorFromString("buttonWithImage:target:action:")
        let methodIMP = buttonClass.method(for: selector)
        let method = unsafeBitCast(methodIMP, to: ButtonCreationMethod.self)
        let button = method(buttonClass, selector, image, target, action)
        button.setValue(11, forKey: "bezelStyle") // textureRounded
        setValue(button, forKey: "view")
        toolTip = CelestiaString("Add", comment: "Add a new item (bookmark)")
    }

    private static var searchItemClassPrepared = false

    static func searchItem(with itemIdentifier: NSToolbarItem.Identifier, currentText: String? = nil, textChangeHandler: @escaping (String?) -> Void, returnHandler: @escaping (String?) -> Void, searchStartHandler: @escaping () -> Void, searchEndHandler: @escaping () -> Void) -> NSToolbarItem {
        if #available(iOS 17, *) {
            let searchTextField = UISearchTextField()
            let item = NSUIViewToolbarItem(itemIdentifier: itemIdentifier, uiView: searchTextField)
            return item
        }
        let item = SearchToolbarItem(itemIdentifier: itemIdentifier, currentText: currentText, textChangeHandler: textChangeHandler, returnHandler: returnHandler, searchStartHandler: searchStartHandler, searchEndHandler: searchEndHandler)
        return item
    }
}
#endif

#if targetEnvironment(macCatalyst)
open class ToolbarSplitContainerController: UIViewController, ToolbarContainerViewController {
    private let split: UISplitViewController
    private var sidebarNavigation: UINavigationController?
    private var secondaryNavigation: UINavigationController?
    private var titleObservation: NSKeyValueObservation?

    public var preferredDisplayMode: UISplitViewController.DisplayMode {
        get { split.preferredDisplayMode }
        set { split.preferredDisplayMode = newValue }
    }

    public var minimumPrimaryColumnWidth: CGFloat {
        get { split.minimumPrimaryColumnWidth }
        set { split.minimumPrimaryColumnWidth = newValue }
    }

    public var maximumPrimaryColumnWidth: CGFloat {
        get { split.maximumPrimaryColumnWidth }
        set { split.maximumPrimaryColumnWidth = newValue }
    }

    private lazy var backToolbarItem = NSToolbarItem(backItemIdentifier: .back, target: self, action: #selector(goBack))
    private var currentToolbarItemIdentifiers: [NSToolbarItem.Identifier] = []

    public init(sidebarViewController: UIViewController? = nil, secondaryViewController: UIViewController? = nil) {
        let sidebarNavigation: ToolbarAwareNavigationController?
        if let sidebarViewController {
            sidebarNavigation = ToolbarAwareNavigationController(rootViewController: sidebarViewController)
        } else {
            sidebarNavigation = nil
        }
        let secondaryNavigation: ToolbarAwareNavigationController?
        if let secondaryViewController {
            secondaryNavigation = ToolbarAwareNavigationController(rootViewController: secondaryViewController)
        } else {
            secondaryNavigation = nil
        }
        self.sidebarNavigation = sidebarNavigation
        self.secondaryNavigation = secondaryNavigation
        split = UISplitViewController(style: .doubleColumn)
        super.init(nibName: nil, bundle: nil)
        split.primaryBackgroundStyle = .sidebar
        split.preferredDisplayMode = .oneBesideSecondary
        split.preferredPrimaryColumnWidthFraction = 0.3
        install(split)
        split.setViewController(sidebarNavigation, for: .primary)
        split.setViewController(secondaryNavigation, for: .secondary)
        sidebarNavigation?.delegate = self
        secondaryNavigation?.delegate = self
    }

    @discardableResult public func setSidebarViewController(_ sidebarViewController: UIViewController) -> UINavigationController {
        sidebarNavigation?.delegate = nil
        let newNavigation = ToolbarAwareNavigationController(rootViewController: sidebarViewController)
        if nsToolbar != nil {
            newNavigation.setNavigationBarHidden(true, animated: false)
        }
        newNavigation.delegate = self
        sidebarNavigation = newNavigation
        split.setViewController(newNavigation, for: .primary)
        updateToolbar()
        return newNavigation
    }

    public func pushSecondaryViewController(_ secondaryViewController: UIViewController, animated: Bool) {
        secondaryNavigation?.pushViewController(secondaryViewController, animated: true)
    }

    @discardableResult public func setSecondaryViewController(_ secondaryViewController: UIViewController) -> UINavigationController {
        secondaryNavigation?.delegate = nil
        let newNavigation = ToolbarAwareNavigationController(rootViewController: secondaryViewController)
        if nsToolbar != nil {
            newNavigation.setNavigationBarHidden(true, animated: false)
        }
        newNavigation.delegate = self
        secondaryNavigation = newNavigation
        split.setViewController(newNavigation, for: .secondary)
        _updateToolbar(for: secondaryViewController)
        return newNavigation
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var nsToolbar: NSToolbar? {
        didSet {
            toolbarDidUpdate(oldValue)
        }
    }

    public func updateToolbar(for viewController: UIViewController) {
        guard viewController == secondaryNavigation?.topViewController else { return }
        _updateToolbar(for: viewController)
    }

    public func _updateToolbar(for viewController: UIViewController) {
        if let vc = viewController as? ToolbarAwareViewController {
            var items = [NSToolbarItem.Identifier]()
            if vc.insertSpaceBeforeToolbarItems(for: self) {
                items.append(.flexibleSpace)
            }
            items += vc.supportedToolbarItemIdentifiers(for: self)
            currentToolbarItemIdentifiers = items
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

        let itemsToInsert = toolbarDefaultItemIdentifiers(nsToolbar)
        for itemToInsert in itemsToInsert.reversed() {
            nsToolbar.insertItem(withItemIdentifier: itemToInsert, at: 0)
        }
    }

    private func toolbarDidUpdate(_ oldToolbar: NSToolbar?) {
        guard oldToolbar != nsToolbar else { return }
        // Remvoe the old items
        if let oldToolbar {
            while !oldToolbar.items.isEmpty {
                oldToolbar.removeItem(at: 0)
            }
        }

        sidebarNavigation?.setNavigationBarHidden(nsToolbar != nil, animated: false)
        secondaryNavigation?.setNavigationBarHidden(nsToolbar != nil, animated: false)

        nsToolbar?.delegate = self
        updateToolbar()
    }

    @objc private func goBack() {
        secondaryNavigation?.popViewController(animated: true)
    }
}

extension ToolbarSplitContainerController: NSToolbarDelegate {
    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        if #available(iOS 17, *) {
            return [.toggleSidebar, .primarySidebarTrackingSeparatorItemIdentifier, .back] + currentToolbarItemIdentifiers
        }
        return [.toggleSidebar, .back] + currentToolbarItemIdentifiers
    }

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        var items = [NSToolbarItem.Identifier]()
        if secondaryNavigation != nil && sidebarNavigation != nil {
            items.append(.toggleSidebar)
            if #available(iOS 17, *) {
                items.append(.primarySidebarTrackingSeparatorItemIdentifier)
            }
        }
        if let secondaryNavigation, secondaryNavigation.viewControllers.count > 1 {
            items.append(.back)
        }
        items += currentToolbarItemIdentifiers
        return items
    }

    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == .back {
            return backToolbarItem
        }
        if itemIdentifier == .flexibleSpace || itemIdentifier == .toggleSidebar {
            return nil
        }
        if #available(iOS 17, *), itemIdentifier == .primarySidebarTrackingSeparatorItemIdentifier {
            return nil
        }
        return (secondaryNavigation?.topViewController as? ToolbarAwareViewController)?.toolbarContainerViewController(self, itemForItemIdentifier: itemIdentifier)
    }
}

extension ToolbarSplitContainerController: ToolbarAwareNavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if navigationController == secondaryNavigation {
            view.window?.windowScene?.title = viewController.title
            titleObservation?.invalidate()
            titleObservation = viewController.observe(\.title) { [weak self] viewController, _ in
                guard let self else { return }
                self.view.window?.windowScene?.title = viewController.title
            }
            _updateToolbar(for: viewController)
        }
    }

    @available(iOS 16, *)
    func fallbackStyleForNavigationController(_ navigationController: UINavigationController) -> ToolbarFallbackStyle {
        return .none
    }
}
#endif
