//
// SettingsCoordinatorController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

public enum SettingAction {
    #if !os(visionOS)
    case refreshFrameRate(newFrameRate: Int)
    #endif
}

#if !os(visionOS)
public struct FrameRateSettingContext {
    let frameRateUserDefaultsKey: String

    public init(frameRateUserDefaultsKey: String) {
        self.frameRateUserDefaultsKey = frameRateUserDefaultsKey
    }
}
#endif

public struct DataLocationSettingContext {
    let userDefaults: UserDefaults
    let dataDirectoryUserDefaultsKey: String
    let configFileUserDefaultsKey: String
    let defaultDataDirectoryURL: URL
    let defaultConfigFileURL: URL

    public init(userDefaults: UserDefaults, dataDirectoryUserDefaultsKey: String, configFileUserDefaultsKey: String, defaultDataDirectoryURL: URL, defaultConfigFileURL: URL) {
        self.userDefaults = userDefaults
        self.dataDirectoryUserDefaultsKey = dataDirectoryUserDefaultsKey
        self.configFileUserDefaultsKey = configFileUserDefaultsKey
        self.defaultConfigFileURL = defaultConfigFileURL
        self.defaultDataDirectoryURL = defaultDataDirectoryURL
    }
}

public class SettingsCoordinatorController: UIViewController {
    #if targetEnvironment(macCatalyst)
    private lazy var controller = ToolbarSplitContainerController()
    #else
    private var navigation: UINavigationController!
    #endif
    private var main: SettingsMainViewController!

    private let core: AppCore
    private let executor: AsyncProviderExecutor
    private let userDefaults: UserDefaults
    private let bundle: Bundle
    private let defaultDataDirectory: URL
    private let settings: [SettingSection]
    #if !os(visionOS)
    private let frameRateContext: FrameRateSettingContext
    #endif
    private let dataLocationContext: DataLocationSettingContext
    #if !os(visionOS)
    private let fontContext: FontSettingContext
    private let toolbarContext: ToolbarSettingContext
    #endif

    private let actionHandler: (SettingAction) -> Void
    private let dateInputHandler: (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?
    private let textInputHandler: (_ viewController: UIViewController, _ title: String, _ keyboardType: UIKeyboardType) async -> String?
    private let rendererInfoProvider: () async -> String
    #if !os(visionOS)
    private let screenProvider: () -> UIScreen
    private let subscriptionManager: SubscriptionManager
    private let openSubscriptionManagement: (UIViewController) -> Void
    #endif

    #if os(visionOS)
    public init(
        core: AppCore,
        executor: AsyncProviderExecutor,
        userDefaults: UserDefaults,
        bundle: Bundle,
        defaultDataDirectory: URL,
        settings: [SettingSection],
        dataLocationContext: DataLocationSettingContext,
        actionHandler: @escaping ((SettingAction) -> Void),
        dateInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?,
        textInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ keyboardType: UIKeyboardType) async -> String?,
        rendererInfoProvider: @escaping () async -> String
    ) {
        self.core = core
        self.executor = executor
        self.userDefaults = userDefaults
        self.bundle = bundle
        self.defaultDataDirectory = defaultDataDirectory
        self.settings = settings
        self.dataLocationContext = dataLocationContext
        self.actionHandler = actionHandler
        self.dateInputHandler = dateInputHandler
        self.textInputHandler = textInputHandler
        self.rendererInfoProvider = rendererInfoProvider
        super.init(nibName: nil, bundle: nil)
    }
    #else
    public init(
        core: AppCore,
        executor: AsyncProviderExecutor,
        userDefaults: UserDefaults,
        bundle: Bundle,
        defaultDataDirectory: URL,
        settings: [SettingSection],
        frameRateContext: FrameRateSettingContext,
        dataLocationContext: DataLocationSettingContext,
        fontContext: FontSettingContext,
        toolbarContext: ToolbarSettingContext,
        actionHandler: @escaping ((SettingAction) -> Void),
        dateInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?,
        textInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ keyboardType: UIKeyboardType) async -> String?,
        rendererInfoProvider: @escaping () async -> String,
        screenProvider: @escaping () -> UIScreen,
        subscriptionManager: SubscriptionManager,
        openSubscriptionManagement: @escaping (UIViewController) -> Void
    ) {
        self.core = core
        self.executor = executor
        self.userDefaults = userDefaults
        self.bundle = bundle
        self.defaultDataDirectory = defaultDataDirectory
        self.settings = settings
        self.frameRateContext = frameRateContext
        self.dataLocationContext = dataLocationContext
        self.toolbarContext = toolbarContext
        self.fontContext = fontContext
        self.actionHandler = actionHandler
        self.dateInputHandler = dateInputHandler
        self.textInputHandler = textInputHandler
        self.rendererInfoProvider = rendererInfoProvider
        self.screenProvider = screenProvider
        self.subscriptionManager = subscriptionManager
        self.openSubscriptionManagement = openSubscriptionManagement
        super.init(nibName: nil, bundle: nil)
    }
    #endif

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()
        #if !os(visionOS)
        view.backgroundColor = .systemBackground
        #endif
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
}

private extension SettingsCoordinatorController {
    func setup() {
        main = SettingsMainViewController(sections: settings, selection: { [weak self] item in
            guard let self else { return }
            let viewController: UIViewController
            switch item.associatedItem {
            case .common(let associated):
                viewController = SettingCommonViewController(core: core, executor: executor, userDefaults: userDefaults, item: associated)
            case .other(let otherType):
                switch otherType {
                case .about:
                    viewController = AboutViewController(bundle: bundle, defaultDirectoryURL: self.defaultDataDirectory)
                case .render:
                    let renderInfo = await self.rendererInfoProvider()
                    viewController = TextViewController(title: item.name, text: renderInfo)
                case .time:
                    viewController = TimeSettingViewController(core: core, executor: executor, dateInputHandler: self.dateInputHandler, textInputHandler: self.textInputHandler)
                case .dataLocation:
                    viewController = DataLocationSelectionViewController(userDefaults: dataLocationContext.userDefaults, dataDirectoryUserDefaultsKey: dataLocationContext.dataDirectoryUserDefaultsKey, configFileUserDefaultsKey: dataLocationContext.configFileUserDefaultsKey, defaultDataDirectoryURL: dataLocationContext.defaultDataDirectoryURL, defaultConfigFileURL: dataLocationContext.defaultConfigFileURL)
#if !os(visionOS)
                case .frameRate:
                    viewController = SettingsFrameRateViewController(screen: self.screenProvider(), userDefaults: userDefaults, userDefaultsKey: frameRateContext.frameRateUserDefaultsKey, frameRateUpdateHandler: { [weak self] newFrameRate in
                        self?.actionHandler(.refreshFrameRate(newFrameRate: newFrameRate))
                    })
                case .font:
                    if #available(iOS 15, *) {
                        viewController = FontSettingMainViewController(context: fontContext, userDefaults: userDefaults, subscriptionManager: subscriptionManager, openSubscriptionManagement: { [weak self] in
                            guard let self else { return }
                            self.openSubscriptionManagement(self)
                        })
                    } else {
                        fatalError()
                    }
                case .toolbar:
                    if #available(iOS 15, *) {
                        viewController = ToolbarSettingViewController(context: toolbarContext, userDefaults: userDefaults, subscriptionManager: subscriptionManager, openSubscriptionManagement: { [weak self] in
                            guard let self else { return }
                            self.openSubscriptionManagement(self)
                        })
                    } else {
                        fatalError()
                    }
#endif
                }
            case .slider, .prefSwitch, .checkmark, .action, .custom, .keyedSelection, .prefSelection, .selection, .prefSlider:
                fatalError("Use .common for slider/action setting item.")
            }
            #if targetEnvironment(macCatalyst)
            self.controller.setSecondaryViewController(viewController)
            #else
            self.navigation.pushViewController(viewController, animated: true)
            #endif
        })
        #if targetEnvironment(macCatalyst)
        controller.setSidebarViewController(main)
        let emptyViewController = UIViewController()
        emptyViewController.view.backgroundColor = .systemBackground
        controller.setSecondaryViewController(emptyViewController)
        install(controller)
        #else
        navigation = UINavigationController(rootViewController: main)
        install(navigation)
        #endif
    }
}

#if targetEnvironment(macCatalyst)
extension SettingsCoordinatorController: ToolbarContainerViewController {
    public var nsToolbar: NSToolbar? {
        get { controller.nsToolbar }
        set { controller.nsToolbar = newValue }
    }

    public func updateToolbar(for viewController: UIViewController) {
        controller.updateToolbar(for: viewController)
    }
}
#endif
