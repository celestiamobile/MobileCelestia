//
//  ToolbarViewController.swift
//  CelestiaMobile
//
//  Created by 李林峰 on 2020/2/23.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

enum ToolbarAction: String {
    case celestia
    case setting
    case share
    case search
    case browse

    static var persistentAction: [ToolbarAction] {
        return [.setting, .share, .search, .browse]
    }
}

class ToolbarViewController: UIViewController {
    private lazy var tableView = UITableView(frame: .zero, style: .plain)

    private let actions: [ToolbarAction]
    private let finishOnSelection: Bool

    private var selectedAction: ToolbarAction?

    var selectionHandler: ((ToolbarAction?) -> Void)?

    init(actions: [ToolbarAction], finishOnSelection: Bool = true) {
        self.actions = actions
        self.finishOnSelection = finishOnSelection
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

    override var preferredContentSize: CGSize {
        get { return CGSize(width: 60, height: 0) }
        set {}
    }

}

extension ToolbarViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ToolbarButtonCell

        cell.backgroundColor = .clear
        cell.itemImage = actions[indexPath.row].image
        cell.actionHandler = { [weak self] in
            guard let self = self else { return }
            if self.finishOnSelection {
                self.dismiss(animated: true, completion: nil)
            }
            self.selectionHandler?(self.actions[indexPath.row])
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

private extension ToolbarViewController {
    func setup() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }

        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()

        tableView.register(ToolbarButtonCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

private extension ToolbarAction {
    var image: UIImage? { return UIImage(named: "toolbar_\(rawValue)") }
}
