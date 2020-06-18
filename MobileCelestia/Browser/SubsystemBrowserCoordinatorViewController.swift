//
//  SubsystemBrowserCoordinatorViewController.swift
//  MobileCelestia
//
//  Created by Levin Li on 2020/6/18.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

class SubsystemBrowserCoordinatorViewController: UIViewController {

    private var navigation: UINavigationController!

    private let item: CelestiaBrowserItem

    private let selection: (CelestiaSelection) -> Void

    init(item: CelestiaBrowserItem, selection: @escaping (CelestiaSelection) -> Void) {
        self.item = item
        self.selection = selection
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

private extension SubsystemBrowserCoordinatorViewController {
    func setup() {
        navigation = UINavigationController(rootViewController: create(for: item))

        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }

    func create(for item: CelestiaBrowserItem) -> BrowserCommonViewController {
        return BrowserCommonViewController(item: item, selection: { [unowned self] (sel, finish) in
            if !finish {
                self.navigation.pushViewController(self.create(for: sel), animated: true)
                return
            }
            guard let transformed = CelestiaSelection(item: sel) else {
                self.showError(CelestiaString("Object not found", comment: ""))
                return
            }
            self.selection(transformed)
        })
    }
}

