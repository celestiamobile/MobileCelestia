//
//  BrowserContainerViewController.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/25.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

class BrowserContainerViewController: UIViewController {
    private lazy var controller = UITabBarController()

    private let selected: (CelestiaSelection) -> Void

    init(selected: @escaping (CelestiaSelection) -> Void) {
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

        setup()
    }

}

private extension BrowserContainerViewController {
    func setup() {
        install(controller)
        let handler = { [unowned self] (selection: CelestiaSelection) in
            self.dismiss(animated: true, completion: nil)
            self.selected(selection)
        }

        controller.setViewControllers([
            BrowserCoordinatorController(item: solBrowserRoot, image: #imageLiteral(resourceName: "browser_tab_sso"), selection: handler),
            BrowserCoordinatorController(item: starBrowserRoot, image: #imageLiteral(resourceName: "browser_tab_star"), selection: handler),
            BrowserCoordinatorController(item: dsoBrowserRoot, image: #imageLiteral(resourceName: "browser_tab_dso"), selection: handler),
        ], animated: false)

        controller.tabBar.barStyle = .black
    }
}
