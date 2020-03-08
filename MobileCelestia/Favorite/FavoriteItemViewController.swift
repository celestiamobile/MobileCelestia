//
//  FavoriteItemViewController.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/3/8.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import CelestiaCore

protocol FavoriteItemList {
    associatedtype Item: FavoriteItem

    var title: String { get }

    var count: Int { get }
    subscript(index: Int) -> Item { get }

    var canBeModified: Bool { get }
    func append(_ item: Item)
    func remove(at index: Int)
}

extension Array: FavoriteItemList where Element == CelestiaScript {
    typealias Item = CelestiaScript

    var title: String {
        return CelestiaString("Scripts", comment: "")
    }

    var canBeModified: Bool { return false }

    func append(_ item: CelestiaScript) {
        fatalError()
    }

    func remove(at index: Int) {
        fatalError()
    }
}

extension BookmarkNode: FavoriteItemList {
    typealias Item = BookmarkNode

    var count: Int {
        return children.count
    }

    subscript(index: Int) -> BookmarkNode {
        return children[index]
    }

    var canBeModified: Bool { return isFolder }

    func append(_ item: BookmarkNode) {
        children.append(item)
    }

    func remove(at index: Int) {
        children.remove(at: index)
    }
}

protocol FavoriteItem {
    associatedtype ItemList: FavoriteItemList
    var title: String { get }
    var associatedURL: URL? { get }
    var isLeaf: Bool { get }
    var itemList: ItemList? { get }
}

extension BookmarkNode: FavoriteItem {
    typealias ItemList = BookmarkNode

    var title: String { return name }

    var associatedURL: URL? {
        return URL(string: url)
    }

    var itemList: BookmarkNode? {
        if !isLeaf {
            return self
        }
        return nil
    }
}

extension CelestiaScript: FavoriteItem {
    typealias ItemList = [CelestiaScript]
    var associatedURL: URL? {
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/" + filename)
    }

    var isLeaf: Bool {
        return true
    }

    var itemList: [CelestiaScript]? {
        return nil
    }
}

class FavoriteItemViewController<ItemList: FavoriteItemList>: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private let itemList: ItemList

    private let selection: (ItemList.Item) -> Void
    private let add: (() -> ItemList.Item?)?

    init(item: ItemList, selection: @escaping (ItemList.Item) -> Void, add: (() -> ItemList.Item?)?) {
        self.itemList = item
        self.selection = selection
        self.add = add
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground

        title = itemList.title
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        let item = itemList[indexPath.row]
        cell.title = item.title
        cell.accessoryType = item.isLeaf ? .none : .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selection(itemList[indexPath.row])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return itemList.canBeModified ? .delete : .none
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            itemList.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }

    @objc private func requestAddObject(_ sender: Any) {
        guard let item = add?() else {
            showError(CelestiaString("Cannot add object.", comment: ""))
            return
        }
        itemList.append(item)
        tableView.reloadData()
    }
}

private extension FavoriteItemViewController {
    func setup() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.separatorColor = .darkSeparator

        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        tableView.dataSource = self
        tableView.delegate = self

        if itemList.canBeModified {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(requestAddObject(_:)))
        }
    }
}
