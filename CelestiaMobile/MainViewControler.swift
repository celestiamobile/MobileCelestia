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

    private lazy var rightSlideInManager = SlideInPresentationManager(direction: .right)
    private lazy var bottomSlideInManager = SlideInPresentationManager(direction: .bottom)

    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .darkBackground

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
    func celestiaController(_ celestiaController: CelestiaViewController, selection: BodyInfo?) {
        var actions: [AppToolbarAction] = AppToolbarAction.persistentAction
        if selection != nil {
            actions.insert(.celestia, at: 0)
        }
        let controller = ToolbarViewController(actions: actions)
        controller.selectionHandler = { [weak self] (action) in
            guard let self = self else { return }
            guard let ac = action as? AppToolbarAction else { return }
            if ac == .celestia {
                self.showBodyInfo(with: selection!)
                return
            }
            switch ac {
            case .celestia:
                self.showBodyInfo(with: selection!)
            case .setting:
                self.showSettings()
            case .search:
                self.showSearch()
            case .browse:
                self.showBrowser()
            case .time:
                self.presentTimeToolbar()
            case .share:
                self.presentShare()
            }
        }
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = rightSlideInManager
        present(controller, animated: true, completion: nil)
    }

    private func presentShare() {
        let image = celestiaController.screenshot()
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        // TODO: iPad presentation
        present(activityController, animated: true, completion: nil)
    }

    private func presentTimeToolbar() {
        let actions: [CelestiaAction] = [.backward, .playpause, .forward]
        let controller = ToolbarViewController(actions: actions, scrollDirection: .horizontal, finishOnSelection: false)
        controller.selectionHandler = { [weak self] (action) in
            guard let self = self else { return }
            guard let ac = action as? CelestiaAction else { return }
            self.celestiaController.receive(action: ac)
        }
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = bottomSlideInManager
        present(controller, animated: true, completion: nil)
    }

    private func showBodyInfo(with selection: BodyInfo) {
        let controller = InfoViewController(info: selection)
        controller.selectionHandler = { [weak self] (action) in
            guard let ac = action else { return }
            guard let self = self else { return }
            switch ac {
            case .select:
                self.celestiaController.select(selection)
            case .wrapped(let cac):
                self.celestiaController.select(selection)
                self.celestiaController.receive(action: cac)
            }
        }
        // TODO: special setup for iPad
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = rightSlideInManager
        present(controller, animated: true, completion: nil)
    }

    private func showSettings() {
        let controller = SettingsCoordinatorController()
        // TODO: special setup for iPad
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = rightSlideInManager
        present(controller, animated: true, completion: nil)
    }

    private func showSearch() {
        let controller = SearchCoordinatorController { [weak self] (info) in
            guard let self = self else { return }
            self.showBodyInfo(with: info)
        }
        // TODO: special setup for iPad
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = rightSlideInManager
        present(controller, animated: true, completion: nil)
    }

    private func showBrowser() {
        let controller = BrowserContainerViewController(selected: { [weak self] (info) in
            guard let self = self else { return }
            self.showBodyInfo(with: info)
        })
        // TODO: special setup for iPad
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = rightSlideInManager
        present(controller, animated: true, completion: nil)
    }
}

extension CelestiaAction: ToolbarAction {
    var image: UIImage? {
        switch self {
        case .playpause:
            return #imageLiteral(resourceName: "time_playpause")
        case .forward:
            return #imageLiteral(resourceName: "time_forward")
        case .backward:
            return #imageLiteral(resourceName: "time_backward")
        default:
            return nil
        }
    }
}
