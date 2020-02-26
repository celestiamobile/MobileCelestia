//
//  BrowserCoordinatorController.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/25.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

class BrowserCoordinatorController: UIViewController {

    private var navigation: UINavigationController!

    override var preferredContentSize: CGSize {
        set {}
        get { return CGSize(width: 300, height: 300) }
    }

    private let item: CelestiaBrowserItem

    private let selection: (BodyInfo) -> Void

    init(item: CelestiaBrowserItem, image: UIImage, selection: @escaping (BodyInfo) -> Void) {
        self.item = item
        self.selection = selection
        super.init(nibName: nil, bundle: nil)

        tabBarItem = UITabBarItem(title: item.name, image: image, selectedImage: nil)
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

private extension BrowserCoordinatorController {
    func setup() {
        navigation = UINavigationController(rootViewController: create(for: item))

        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }

    func create(for item: CelestiaBrowserItem) -> BrowserCommonViewController {
        return BrowserCommonViewController(item: item, selection: { [weak self] (sel, finish) in
            guard let self = self else { return }
            if !finish {
                self.navigation.pushViewController(self.create(for: sel), animated: true)
                return
            }
            guard let transformed = CelestiaSelection(item: sel) else {
                // TODO: handle error
                return
            }
            CelestiaAppCore.shared.simulation.selection = transformed
            self.selection(BodyInfo(selection: transformed))
        })
    }
}

