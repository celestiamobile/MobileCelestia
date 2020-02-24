//
//  SearchCoordinatorController.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class SearchCoordinatorController: UIViewController {

    private var main: SearchViewController!
    private var navigation: UINavigationController!

    override var preferredContentSize: CGSize {
        set {}
        get { return CGSize(width: 300, height: 300) }
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
        main = SearchViewController()
        navigation = UINavigationController(rootViewController: main)

        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }
}
