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

public final class SelectionViewController: UICollectionViewController {
    private let options: [String]
    private var selectedIndex: Int?
    private let selectionChange: (Int) -> Void

    public init(title: String, options: [String], selectedIndex: Int?, selectionChange: @escaping (Int) -> Void) {
        self.options = options
        self.selectedIndex = selectedIndex
        self.selectionChange = selectionChange
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: .init(appearance: .defaultGrouped)))
        self.title = title
        self.windowTitle = title
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "Cell")
    }
}

extension SelectionViewController {
    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! UICollectionViewListCell
        var configuration = UIListContentConfiguration.celestiaCell()
        configuration.text = options[indexPath.item]
        cell.contentConfiguration = configuration
        cell.accessories = indexPath.row == selectedIndex ? [.checkmark()] : []
        return cell
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        selectedIndex = indexPath.item
        collectionView.reloadData()
        selectionChange(indexPath.row)
    }
}


