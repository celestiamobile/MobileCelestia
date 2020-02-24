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

    private lazy var slideInManager = SlideInPresentationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        install(celestiaController)
        celestiaController.celestiaDelegate = self
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

extension MainViewControler: CelestiaViewControllerDelegate {
    func celestiaController(_ celestiaController: CelestiaViewController, supportedActions: [CelestiaAction], completion: (CelestiaAction?) -> Void) {
        slideInManager.direction = .right
        var actions: [ToolbarAction] = ToolbarAction.persistentAction
        if !supportedActions.isEmpty {
            actions.insert(.celestia, at: 0)
        }
        let controller = ToolbarViewController(actions: actions)
        controller.selectionHandler = { action in
            // TODO: handle action selection and call completion
        }
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = slideInManager
        present(controller, animated: true, completion: nil)
    }
}
