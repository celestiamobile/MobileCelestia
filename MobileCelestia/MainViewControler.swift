//
//  MainViewControler.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/23.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import SafariServices

import MBProgressHUD

private let userInitiatedDismissalFlag = 1

class MainViewControler: UIViewController {
    private lazy var celestiaController = CelestiaViewController()

    private var loadeed = false

    private lazy var rightSlideInManager = SlideInPresentationManager(direction: .right)
    private lazy var bottomSlideInManager = SlideInPresentationManager(direction: .bottom)

    private var viewControllerStack: [UIViewController] = []

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

        var retried = false

        let loadingController = LoadingViewController()
        install(loadingController)

        celestiaController.load(statusUpdater: { (status) in
            loadingController.update(with: status)
        }, errorHandler: { [unowned self] in
            if retried { return false }
            // TODO: display an error
            DispatchQueue.main.async { self.showError(CelestiaString("Error loading data, fallback to original configuration.", comment: "")) }
            retried = true
            saveConfigFile(nil)
            saveDataDirectory(nil)
            return true
        }, completionHandler: { [unowned self] (result) in
            loadingController.remove()

            switch result {
            case .success():
                print("loading success")
                self.showOnboardMessageIfNeeded()
            case .failure(_):
                let failure = LoadingFailureViewController()
                self.install(failure)
            }
        })
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
        controller.selectionHandler = { [unowned self] (action) in
            guard let ac = action as? AppToolbarAction else { return }
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
                self.presentShare(selection: selection)
            }
        }
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = rightSlideInManager
        present(controller, animated: true, completion: nil)
    }

    private func presentShare(selection: BodyInfo?) {
        let url = celestiaController.currentURL.absoluteString
        showTextInput(CelestiaString("Description", comment: ""),
                      message: CelestiaString("Please enter a description of the content.", comment: ""),
                      text: selection?.name) { (description) in
                        self.submitURL(url, title: description)
        }
    }

    private func presentTimeToolbar() {
        let actions: [CelestiaAction] = [.backward, .playpause, .forward]
        let controller = ToolbarViewController(actions: actions, scrollDirection: .horizontal, finishOnSelection: false)
        controller.selectionHandler = { [unowned self] (action) in
            guard let ac = action as? CelestiaAction else { return }
            self.celestiaController.receive(action: ac)
        }
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = bottomSlideInManager
        present(controller, animated: true, completion: nil)
    }

    private func showBodyInfo(with selection: BodyInfo) {
        let controller = InfoViewController(info: selection)
        controller.dismissDelegate = self
        controller.selectionHandler = { [unowned self] (action) in
            guard let ac = action else { return }
            switch ac {
            case .select:
                self.celestiaController.select(selection)
            case .wrapped(let cac):
                self.celestiaController.select(selection)
                self.celestiaController.receive(action: cac)
            case .web(let url):
                self.addToBackStack()
                self.showWeb(url)
            }
        }
        showViewController(controller)
    }

    private func showWeb(_ url: URL) {
        let sf = SFSafariViewController(url: url)
        sf.dismissDelegate = self
        showViewController(sf)
    }

    private func showSettings() {
        let controller = SettingsCoordinatorController() { [unowned self] (action) in
            switch action {
            case .tutorial(let tutorial):
                self.handleTutorialAction(tutorial)
            }
        }
        showViewController(controller)
    }

    private func showSearch() {
        let controller = SearchCoordinatorController { [unowned self] (info) in
            self.addToBackStack()
            self.showBodyInfo(with: info)
        }
        showViewController(controller)
    }

    private func showBrowser() {
        let controller = BrowserContainerViewController(selected: { [unowned self] (info) in
            self.addToBackStack()
            self.showBodyInfo(with: info)
        })
        showViewController(controller)
    }

    private func showViewController(_ viewController: UIViewController) {
        viewController.customFlag &= ~userInitiatedDismissalFlag
        if UIDevice.current.userInterfaceIdiom == .pad {
            configurePopover(for: viewController)
        } else {
            viewController.preferredContentSize = CGSize(width: 300, height: 300)
            viewController.modalPresentationStyle = .custom
            viewController.transitioningDelegate = rightSlideInManager
        }
        present(viewController, animated: true, completion: nil)
    }

    private func configurePopover(for viewController: UIViewController) {
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.sourceView = view
        viewController.popoverPresentationController?.sourceRect = CGRect(x: view.frame.midX, y: view.frame.midY, width: 0, height: 0)
        viewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        viewController.preferredContentSize = CGSize(width: 400, height: 500)
    }
}

extension MainViewControler {
    private func handleTutorialAction(_ action: TutorialAction) {
        dismiss(animated: true, completion: nil)
        switch action {
        case .runDemo:
            celestiaController.receive(action: .runDemo)
        }
    }

    private func showOnboardMessageIfNeeded() {
        let onboardMessageDisplayed: Bool? = UserDefaults.app[.onboardMessageDisplayed]
        if onboardMessageDisplayed == nil {
            UserDefaults.app[.onboardMessageDisplayed] = true
            showViewController(OnboardViewController() { [unowned self] (action) in
                switch action {
                case .tutorial(let tutorial):
                    self.handleTutorialAction(tutorial)
                }
            })
        }
    }
}

extension MainViewControler {
    private func submitURL(_ url: String, title: String?) {
        let requestURL = "https://meowssage.cc/celestia/create"

        struct URLCreationResponse: Decodable {
            let publicURL: String
        }

        let showUnknownError = { [unowned self] in
            self.showError(CelestiaString("Unknown error", comment: ""))
        }

        guard let data = url.data(using: .utf8) else {
            showUnknownError()
            return
        }

        MBProgressHUD.showAdded(to: view, animated: true)
        _ = RequestHandler.post(url: requestURL, params: [
            "title" : title ?? CelestiaString("Unnamed", comment: ""),
            "url" : data.base64EncodedURLString(),
            "version" : Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        ], success: { [unowned self] (result: URLCreationResponse) in
            MBProgressHUD.hide(for: self.view, animated: true)
            guard let url = URL(string: result.publicURL) else {
                showUnknownError()
                return
            }
            self.showShareSheet(for: url)
        }, fail: { [unowned self] (error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            showUnknownError()
        })
    }

    private func showShareSheet(for url: URL) {
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        configurePopover(for: activityController)
        present(activityController, animated: true, completion: nil)
    }
}

extension MainViewControler: UIViewControllerDismissDelegate {
    func viewControllerDidDismiss(_ viewController: UIViewController) {
        if (viewController.customFlag & userInitiatedDismissalFlag) == 0 {
            popLastAndShow()
        }
    }

    func popLastAndShow() {
        if let viewController = viewControllerStack.popLast() {
            showViewController(viewController)
        }
    }

    func addToBackStack() {
        if let current = presentedViewController {
            viewControllerStack.append(current)
            current.customFlag |= userInitiatedDismissalFlag
            current.dismiss(animated: true, completion: nil)
        }
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
