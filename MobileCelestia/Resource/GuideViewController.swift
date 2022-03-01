//
// GuideViewController.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

class GuideViewController: UIViewController {
    private var main: GuideListViewController!
    private var navigation: UINavigationController!

    private let type: String
    private let listTitle: String

    init(type: String, title: String) {
        self.type = type
        self.listTitle = title
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

        setUp()
    }
}

private extension GuideViewController {
    func setUp() {
        main = GuideListViewController(type: type, title: listTitle, selection: { [weak self] item in
            guard let self = self else { return }
            self.navigation.pushViewController(CommonWebViewController(url: .fromGuide(guideItemID: item.id, language: LocalizedString("LANGUAGE", "celestia"))), animated: true)
        })
        navigation = UINavigationController(rootViewController: main)
        install(navigation)
        if #available(iOS 13.0, *) {
        } else {
            navigation.navigationBar.barStyle = .black
            navigation.navigationBar.barTintColor = .darkBackground
            navigation.navigationBar.titleTextAttributes?[.foregroundColor] = UIColor.darkLabel
        }
    }
}
