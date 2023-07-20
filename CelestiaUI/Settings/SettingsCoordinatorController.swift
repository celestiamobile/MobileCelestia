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
    case refreshFrameRate(newFrameRate: Int)
}

public struct FrameRateSettingContext {
    let frameRateUserDefaultsKey: String

    public init(frameRateUserDefaultsKey: String) {
        self.frameRateUserDefaultsKey = frameRateUserDefaultsKey
    }
}

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
    private lazy var controller: UISplitViewController = {
        if #available(macCatalyst 16, *) {
            return UISplitViewController(style: .doubleColumn)
        } else {
            return UISplitViewController()
        }
    }()
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
    private let frameRateContext: FrameRateSettingContext
    private let dataLocationContext: DataLocationSettingContext

    private let actionHandler: (SettingAction) -> Void
    private let dateInputHandler: (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?
    private let rendererInfoProvider: () async -> String
    private let screenProvider: () -> UIScreen

    public init(
        core: AppCore,
        executor: AsyncProviderExecutor,
        userDefaults: UserDefaults,
        bundle: Bundle,
        defaultDataDirectory: URL,
        settings: [SettingSection],
        frameRateContext: FrameRateSettingContext,
        dataLocationContext: DataLocationSettingContext,
        actionHandler: @escaping ((SettingAction) -> Void),
        dateInputHandler: @escaping (_ viewController: UIViewController, _ title: String, _ format: String) async -> Date?,
        rendererInfoProvider: @escaping () async -> String,
        screenProvider: @escaping () -> UIScreen
    ) {
        self.core = core
        self.executor = executor
        self.userDefaults = userDefaults
        self.bundle = bundle
        self.defaultDataDirectory = defaultDataDirectory
        self.settings = settings
        self.frameRateContext = frameRateContext
        self.dataLocationContext = dataLocationContext
        self.actionHandler = actionHandler
        self.dateInputHandler = dateInputHandler
        self.rendererInfoProvider = rendererInfoProvider
        self.screenProvider = screenProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        core.store(userDefaults)
    }
}

private extension SettingsCoordinatorController {
    func setup() {
        main = SettingsMainViewController(sections: settings, selection: { [weak self] item in
            guard let self else { return }
            func logWrongAssociatedItemType(_ item: AnyHashable) -> Never {
                fatalError("Wrong associated item \(item.base)")
            }

            let viewController: UIViewController
            switch item.type {
            case .common:
                if let associated = item.associatedItem.base as? AssociatedCommonItem {
                    viewController = SettingCommonViewController(core: core, executor: executor, userDefaults: userDefaults, item: associated)
                } else {
                    logWrongAssociatedItemType(item.associatedItem)
                }
            case .about:
                viewController = AboutViewController(bundle: bundle, defaultDirectoryURL: self.defaultDataDirectory)
            case .time:
                viewController = TimeSettingViewController(core: core, executor: executor, dateInputHandler: self.dateInputHandler)
            case .render:
                let renderInfo = await self.rendererInfoProvider()
                viewController = TextViewController(title: item.name, text: renderInfo)
            case .dataLocation:
                viewController = DataLocationSelectionViewController(userDefaults: dataLocationContext.userDefaults, dataDirectoryUserDefaultsKey: dataLocationContext.dataDirectoryUserDefaultsKey, configFileUserDefaultsKey: dataLocationContext.configFileUserDefaultsKey, defaultDataDirectoryURL: dataLocationContext.defaultDataDirectoryURL, defaultConfigFileURL: dataLocationContext.defaultConfigFileURL)
            case .frameRate:
                viewController = SettingsFrameRateViewController(screen: self.screenProvider(), userDefaults: userDefaults, userDefaultsKey: frameRateContext.frameRateUserDefaultsKey, frameRateUpdateHandler: { [weak self] newFrameRate in
                    self?.actionHandler(.refreshFrameRate(newFrameRate: newFrameRate))
                })
            case .slider, .prefSwitch, .checkmark, .action, .custom, .keyedSelection, .prefSelection, .selection:
                fatalError("Use .common for slider/action setting item.")
            }
            #if targetEnvironment(macCatalyst)
            let navigationController = ContentNavigationController(rootViewController: viewController)
            if #available(macCatalyst 16, *) {
                self.controller.setViewController(navigationController, for: .secondary)
                if let windowScene = self.controller.view.window?.windowScene {
                    windowScene.titlebar?.titleVisibility = .visible
                }
            } else {
                self.controller.viewControllers = [self.controller.viewControllers[0], navigationController]
            }
            #else
            self.navigation.pushViewController(viewController, animated: true)
            #endif
        })
        #if targetEnvironment(macCatalyst)
        controller.primaryBackgroundStyle = .sidebar
        controller.preferredDisplayMode = .oneBesideSecondary
        controller.preferredPrimaryColumnWidthFraction = 0.3
        let emptyVc = UIViewController()
        emptyVc.view.backgroundColor = .systemBackground
        if #available(macCatalyst 16, *) {
            controller.setViewController(SidebarNavigationController(rootViewController: main), for: .primary)
            controller.setViewController(ContentNavigationController(rootViewController: emptyVc), for: .secondary)
        } else {
            controller.viewControllers = [main, ContentNavigationController(rootViewController: emptyVc)]
        }
        install(controller)
        #else
        navigation = UINavigationController(rootViewController: main)
        install(navigation)
        #endif
    }
}
