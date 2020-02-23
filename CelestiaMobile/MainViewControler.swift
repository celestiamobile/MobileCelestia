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

    override func viewDidLoad() {
        super.viewDidLoad()

        install(celestiaController)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
         return true
    }
}
