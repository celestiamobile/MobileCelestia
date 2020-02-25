//
//  BrowserContainerViewController.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/25.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

class BrowserContainerViewController: UIViewController {
    private lazy var controller = UITabBarController()

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

    override var preferredContentSize: CGSize {
        set {}
        get { return CGSize(width: 300, height: 300) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

private extension BrowserContainerViewController {
    func setup() {
        install(controller)

        controller.setViewControllers(browserRoots.map { BrowserCoordinatorController(item: $0) { [weak self] (selection) in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
            self.selected(selection)
        } }, animated: false)
    }
}
