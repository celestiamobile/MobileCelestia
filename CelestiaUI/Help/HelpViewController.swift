//
// HelpViewController.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

public final class HelpViewController: UIViewController {
    private let executor: AsyncProviderExecutor
    private let resourceManager: ResourceManager

    public init(executor: AsyncProviderExecutor, resourceManager: ResourceManager) {
        self.executor = executor
        self.resourceManager = resourceManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        let url = URL.fromGuideShort(path: "/help/welcome", language: AppCore.language, shareable: false)
        let vc = FallbackWebViewController(executor: executor, resourceManager: resourceManager, url: url, fallbackViewControllerCreator: OnboardViewController() { [weak self] action in
            guard let self else { return }
            switch action {
            case .tutorial(let tutorial):
                switch tutorial {
                case .runDemo:
                    Task {
                        await self.executor.run { $0.receive(.runDemo) }
                    }
                }
            case .url(let url):
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })
        let nav = UINavigationController(rootViewController: vc)
        nav.setNavigationBarHidden(true, animated: false)
        install(nav)
    }
}
