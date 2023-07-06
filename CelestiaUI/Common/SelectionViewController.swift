//
// SelectionViewController.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

public final class SelectionViewController: BaseTableViewController {
    private let options: [String]
    private var selectedIndex: Int?
    private let selectionChange: (Int) -> Void

    public init(title: String, options: [String], selectedIndex: Int?, selectionChange: @escaping (Int) -> Void) {
        self.options = options
        self.selectedIndex = selectedIndex
        self.selectionChange = selectionChange
        super.init(style: .defaultGrouped)
        self.title = title
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(TextCell.self, forCellReuseIdentifier: "Cell")
    }
}

extension SelectionViewController {
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TextCell
        cell.title = options[indexPath.row]
        cell.accessoryType = indexPath.row == selectedIndex ? .checkmark : .none
        return cell
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedIndex = indexPath.row
        tableView.reloadData()
        selectionChange(indexPath.row)
    }
}


