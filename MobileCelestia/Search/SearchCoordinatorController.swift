//
//  SearchCoordinatorController.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

class SearchCoordinatorController: UIViewController {

    private var main: SearchViewController!
    private var navigation: UINavigationController!

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

private extension SearchCoordinatorController {
    func setup() {
        main = SearchViewController(selected: { [unowned self] (info) in
            self.dismiss(animated: true, completion: nil)
            self.selected(info)
        })
        navigation = UINavigationController(rootViewController: main)

        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }
}
