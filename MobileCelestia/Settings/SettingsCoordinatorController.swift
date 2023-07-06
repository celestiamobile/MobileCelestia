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
import CelestiaUI
import UIKit

enum SettingAction {
    case refreshFrameRate(newFrameRate: Int)
}

class SettingsCoordinatorController: UIViewController {
    #if targetEnvironment(macCatalyst)
    private lazy var controller = UISplitViewController()
    #else
    private var navigation: UINavigationController!
    #endif
    private var main: SettingsMainViewController!

    @Injected(\.appCore) private var core
    @Injected(\.executor) private var executor
    @Injected(\.userDefaults) private var userDefaults

    private let actionHandler: ((SettingAction) -> Void)
    private let screenProvider: (() -> UIScreen)

    init(actionHandler: @escaping ((SettingAction) -> Void), screenProvider: @escaping () -> UIScreen) {
        self.actionHandler = actionHandler
        self.screenProvider = screenProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        core.store(userDefaults)
    }
}

private extension SettingsCoordinatorController {
    func setup() {
        main = SettingsMainViewController(selection: { [unowned self] (item) in
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
                viewController = AboutViewController(bundle: .app, defaultDirectoryURL: UserDefaults.defaultDataDirectory)
            case .time:
                viewController = TimeSettingViewController(core: core, executor: executor, dateInputHandler: { viewController, title, format in
                    return await viewController.getDateInputDifferentiated(title, format: format)
                })
            case .render:
                let renderInfo = self.executor.get { core -> String in
                    self.executor.makeRenderContextCurrent()
                    return core.renderInfo
                }
                viewController = TextViewController(title: item.name, text: renderInfo)
            case .dataLocation:
                viewController = DataLocationSelectionViewController(userDefaults: userDefaults, dataDirectoryUserDefaultsKey: UserDefaultsKey.dataDirPath.rawValue, configFileUserDefaultsKey: UserDefaultsKey.configFile.rawValue, defaultDataDirectoryURL: UserDefaults.defaultDataDirectory, defaultConfigFileURL: UserDefaults.defaultConfigFile)
            case .frameRate:
                viewController = SettingsFrameRateViewController(screen: self.screenProvider(), userDefaults: userDefaults, userDefaultsKey: UserDefaultsKey.frameRate.rawValue, frameRateUpdateHandler: { [weak self] newFrameRate in
                    self?.actionHandler(.refreshFrameRate(newFrameRate: newFrameRate))
                })
            case .slider, .prefSwitch, .checkmark, .action, .custom, .keyedSelection, .prefSelection, .selection:
                fatalError("Use .common for slider/action setting item.")
            }
            #if targetEnvironment(macCatalyst)
            let navigationController: UINavigationController
            if #available(iOS 16, *) {
                navigationController = SettingsNavigationController(rootViewController: viewController)
            } else {
                navigationController = UINavigationController(rootViewController: viewController)
            }
            self.controller.viewControllers = [self.controller.viewControllers[0], navigationController]
            if #available(iOS 16.0, *) {
                if let windowScene = self.controller.view.window?.windowScene {
                    windowScene.titlebar?.titleVisibility = .visible
                }
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
        controller.viewControllers = [main, emptyVc]
        install(controller)
        #else
        navigation = UINavigationController(rootViewController: main)
        install(navigation)
        #endif
    }
}

#if targetEnvironment(macCatalyst)
@available(macCatalyst 16.0, *)
class SettingsNavigationController: UINavigationController, UINavigationBarDelegate {
    func navigationBarNSToolbarSection(_ navigationBar: UINavigationBar) -> UINavigationBar.NSToolbarSection {
        return .content
    }
}
#endif
