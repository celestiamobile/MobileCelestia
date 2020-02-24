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

    private let selected: (BodyInfo) -> Void

    init(selected: @escaping (BodyInfo) -> Void) {
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
        main = SearchViewController(selected: { [weak self] (info) in
            self?.dismiss(animated: true, completion: nil)
            self?.selected(info)
        })
        navigation = UINavigationController(rootViewController: main)

        install(navigation)

        navigation.navigationBar.barStyle = .black
        navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
    }
}
