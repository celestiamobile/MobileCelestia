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
    func move(from source: Int, to dest: Int)
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

    func move(from source: Int, to dest: Int) {
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

    func move(from source: Int, to dest: Int) {
        children.insert(children.remove(at: source), at: dest)
    }
}

protocol FavoriteItem {
    associatedtype ItemList: FavoriteItemList
    var title: String { get }
    var associatedURL: URL? { get }
    var isLeaf: Bool { get }
    var itemList: ItemList? { get }
    var canBeRenamed: Bool { get }

    func rename(to name: String)
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

    var canBeRenamed: Bool { return true }

    func rename(to name: String) {
        self.name = name
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

    var canBeRenamed: Bool { return false }

    func rename(to name: String) {
        fatalError()
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

    func numberOfSections(in tableView: UITableView) -> Int {
        if itemList.canBeModified { return 2 }
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 { return 1 }
        return itemList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
        if indexPath.section == 1 {
            cell.title = CelestiaString("Add new...", comment: "")
            cell.accessoryType = .disclosureIndicator
        } else {
            let item = itemList[indexPath.row]
            cell.title = item.title
            cell.accessoryType = item.isLeaf ? .none : .disclosureIndicator
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            requestAddObject()
        } else {
            selection(itemList[indexPath.row])
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.section == 1 { return nil }
        var actions = [UITableViewRowAction]()
        if itemList.canBeModified {
            actions.append(
                UITableViewRowAction(style: .destructive, title: CelestiaString("Delete", comment: "")) { [unowned self] (_, indexPath) in
                    self.requestRemoveObject(at: indexPath.row)
            })
        }
        let item = itemList[indexPath.row]
        if item.canBeRenamed {
            actions.append(
                UITableViewRowAction(style: .normal, title: CelestiaString("Edit", comment: "")) { [unowned self] (_, indexPath) in
                    self.requestRenameObject(at: indexPath.row)
            })
        }
        return actions
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return itemList.canBeModified && indexPath.section == 0
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return itemList.canBeModified && indexPath.section == 0
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        defer { tableView.reloadData() }
        guard destinationIndexPath.section == 0 else { return }
        itemList.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }

    // MARK: Modification
    @objc private func requestEdit() {
        tableView.setEditing(true, animated: true)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(finishEditing))
    }

    @objc private func finishEditing() {
        tableView.setEditing(false, animated: true)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(requestEdit))
    }

    private func requestAddObject() {
        guard let item = add?() else {
            showError(CelestiaString("Cannot add object", comment: ""))
            return
        }
        itemList.append(item)
        tableView.reloadData()
    }

    private func requestRemoveObject(at index: Int) {
        itemList.remove(at: index)
        tableView.reloadData()
    }

    private func requestRenameObject(at index: Int) {
        let item = itemList[index]
        showTextInput(CelestiaString("Please enter a new name.", comment: ""), text: item.title) { [unowned self] (text) in
            guard let newName = text else { return }
            item.rename(to: newName)
            self.tableView.reloadData()
        }
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
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(requestEdit))
        }
    }
}
