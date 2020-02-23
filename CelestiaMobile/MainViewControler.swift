//
//  MainViewControler.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/23.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class MainViewControler: UIViewController {
    private lazy var celestiaController = CelestiaViewController()

    private var loadeed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        install(celestiaController)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if loadeed { return }

        loadeed = true

        let loadingController = LoadingViewController()
        install(loadingController)

        celestiaController.load({ (status) in
            loadingController.update(with: status)
        }) { (result) in
            loadingController.remove()

            switch result {
            case .success():
                print("loading success")
            case .failure(_):
                let failure = LoadingFailureViewController()
                self.install(failure)
            }
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
         return true
    }
}
