// ToolbarAwareViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

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

    public var topViewController: UIViewController? {
        return navigation.topViewController
    }

    public init(rootViewController: UIViewController) {
        #if targetEnvironment(macCatalyst)
        let vc = ToolbarAwareNavigationController(rootViewController: rootViewController)
        navigation = vc
        #else
        navigation = BaseNavigationController(rootViewController: rootViewController)
        #endif
        super.init(nibName: nil, bundle: nil)
        install(navigation)
        observeWindowTitle(for: navigation)
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
@MainActor
protocol ToolbarAwareNavigationControllerDelegate: UINavigationControllerDelegate {
    @available(iOS 16, *)
    func fallbackStyleForNavigationController(_ navigationController: UINavigationController) -> ToolbarFallbackStyle
}

private class ToolbarAwareNavigationController: BaseNavigationController {}

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


    private struct AssociatedKeys {
        @MainActor
        static var searchFieldDelegate: UInt8 = 0
    }

    private static var searchItemClassPrepared = false

    static func searchItem(with itemIdentifier: NSToolbarItem.Identifier, currentText: String? = nil, textChangeHandler: @escaping (String?) -> Void, returnHandler: @escaping (String?) -> Void, searchStartHandler: @escaping () -> Void, searchEndHandler: @escaping () -> Void) -> NSToolbarItem {
        if !Self.searchItemClassPrepared {
            if let delegateProtocol = objc_getProtocol("NSSearchFieldDelegate") {
                class_addProtocol(SearchFieldDelegate.self, delegateProtocol)
                Self.searchItemClassPrepared = SearchFieldDelegate.conforms(to: delegateProtocol)
            }
        }

        let delegate = SearchFieldDelegate(textChangeHandler: textChangeHandler, returnHandler: returnHandler, searchStartHandler: searchStartHandler, searchEndHandler: searchEndHandler)
        let clazz = NSClassFromString("NSSearchToolbarItem") as! NSToolbarItem.Type
        let item = clazz.init(itemIdentifier: itemIdentifier)
        let searchField = item.value(forKey: "searchField") as! NSObject
        if let currentText {
            searchField.setValue(currentText, forKey: "stringValue")
        }
        if Self.searchItemClassPrepared {
            searchField.perform(NSSelectorFromString("setDelegate:"), with: delegate)
        }
        searchField.perform(NSSelectorFromString("setTarget:"), with: delegate)
        let selector = NSSelectorFromString("setAction:")
        typealias SetActionMethod = @convention(c) (NSObject, Selector, Selector) -> Void
        let methodIMP = searchField.method(for: selector)
        let method = unsafeBitCast(methodIMP, to: SetActionMethod.self)
        method(searchField, selector, #selector(SearchFieldDelegate.textChanged(_:)))
        objc_setAssociatedObject(item, &AssociatedKeys.searchFieldDelegate, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return item
    }
}

private final class SearchFieldDelegate: NSObject {
    private let textChangeHandler: (String?) -> Void
    private let returnHandler: (String?) -> Void
    private let searchStartHandler: () -> Void
    private let searchEndHandler: () -> Void

    init(textChangeHandler: @escaping (String?) -> Void, returnHandler: @escaping (String?) -> Void, searchStartHandler: @escaping () -> Void, searchEndHandler: @escaping () -> Void) {
        self.textChangeHandler = textChangeHandler
        self.returnHandler = returnHandler
        self.searchStartHandler = searchStartHandler
        self.searchEndHandler = searchEndHandler
        super.init()
    }

    @objc func textChanged(_ sender: NSObject) {
        let value = sender.value(forKey: "stringValue") as? String
        textChangeHandler(value)
    }

    @objc(control:textView:doCommandBySelector:) func control(_ control: NSObject, textView: NSObject, doCommandBySelector selector: Selector) -> Bool {
        if selector == NSSelectorFromString("insertNewline:") {
            let value = control.value(forKey: "stringValue") as? String
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
#endif

#if targetEnvironment(macCatalyst)
open class ToolbarSplitContainerController: UIViewController, ToolbarContainerViewController {
    private let split: UISplitViewController
    private var sidebarNavigation: BaseNavigationController?
    private var secondaryNavigation: BaseNavigationController?
    private var secondaryNavigationIsPlaceholder = false

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
        updateTitleObservation()
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
        updateTitleObservation()
        return newNavigation
    }

    public func pushSecondaryViewController(_ secondaryViewController: UIViewController, animated: Bool) {
        secondaryNavigation?.pushViewController(secondaryViewController, animated: true)
    }

    @discardableResult public func setSecondaryAndCompactViewController(_ secondaryViewController: UIViewController, isPlaceholder: Bool = false) -> UINavigationController {
        secondaryNavigation?.delegate = nil
        let newNavigation = ToolbarAwareNavigationController(rootViewController: secondaryViewController)
        if nsToolbar != nil {
            newNavigation.setNavigationBarHidden(true, animated: false)
        }
        newNavigation.delegate = self
        secondaryNavigation = newNavigation
        secondaryNavigationIsPlaceholder = isPlaceholder
        split.setViewController(newNavigation, for: .secondary)
        split.setViewController(newNavigation, for: .compact)
        _updateToolbar(for: secondaryViewController)
        updateTitleObservation()
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

    private func updateTitleObservation() {
        stopObservingWindowTitle()
        let observingViewController: UIViewController?
        if let secondaryNavigation, !secondaryNavigationIsPlaceholder {
            observingViewController = secondaryNavigation
        } else if let sidebarNavigation {
            observingViewController = sidebarNavigation
        } else {
            observingViewController = nil
        }

        if let observingViewController {
            observeWindowTitle(for: observingViewController)
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
            _updateToolbar(for: viewController)
        }
    }

    @available(iOS 16, *)
    func fallbackStyleForNavigationController(_ navigationController: UINavigationController) -> ToolbarFallbackStyle {
        return .none
    }
}
#else
public typealias ToolbarSplitContainerController = UISplitViewController

public extension ToolbarSplitContainerController {
    @discardableResult func setSecondaryAndCompactViewController(_ secondaryViewController: UIViewController) -> UINavigationController {
        let navigation = UINavigationController(rootViewController: secondaryViewController)
        navigation.setNavigationBarHidden(true, animated: false)
        setViewController(navigation, for: .secondary)
        setViewController(navigation, for: .compact)
        return navigation
    }
}
#endif
