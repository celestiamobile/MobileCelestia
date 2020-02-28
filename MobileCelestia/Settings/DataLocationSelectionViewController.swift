//
//  DataLocationSelectionViewController.swift
//  MobileCelestia
//
//  Created by Li Linfeng on 2020/2/28.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

import MobileCoreServices

class DataLocationSelectionViewController: UIViewController {

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    private var items: [[TextItem]] = []

    private enum Location: Int {
        case dataDirectory
        case configFile
    }

    private var currentPicker: Location?

    override func loadView() {
        view = UIView()
        view.backgroundColor = .darkBackground

        title = CelestiaString("Data Location", comment: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadContents()
    }

    private func loadContents() {
        var totalItems = [[TextItem]]()

        totalItems.append([
            TextItem.short(title: CelestiaString("Data Directory", comment: ""),
                           detail: currentDataDirectory().url == defaultDataDirectory ? CelestiaString("Default", comment: "") : CelestiaString("Custom", comment: "")),
            TextItem.short(title: CelestiaString("Config File", comment: ""),
                           detail: currentConfigFile().url == defaultConfigFile ? CelestiaString("Default", comment: "") : CelestiaString("Custom", comment: "")),
        ])

        totalItems.append([
            TextItem.short(title: CelestiaString("Reset to Default", comment: ""), detail: nil),
        ])

        items = totalItems
        tableView.reloadData()
    }
}

private extension DataLocationSelectionViewController {
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
    }
}

extension DataLocationSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .short(let title, let detail):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Text", for: indexPath) as! SettingTextCell
            cell.title = title
            cell.detail = detail
            cell.selectionStyle = .default
            cell.accessoryType = indexPath.section == 0 ? .disclosureIndicator : .none
            return cell
        default:
            fatalError()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .short(_, _):
            fallthrough
        case .link(_, _):
            return 44
        case .long(_):
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            saveDataDirectory(nil)
            saveConfigFile(nil)

            loadContents()
        } else {
            let type = [kUTTypeFolder as String, "space.celestia.config"][indexPath.row]
            currentPicker = Location(rawValue: indexPath.row)
            let browser = UIDocumentPickerViewController(documentTypes: [type], in: .open)
            browser.allowsMultipleSelection = false
            browser.delegate = self
            present(browser, animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

extension DataLocationSelectionViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        // try to start reading
        if !url.startAccessingSecurityScopedResource() {
            showError(CelestiaString("Operation not permitted.", comment: ""))
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // save the bookmark for next launch
        do {
            let bookmark = try url.bookmarkData(options: .init(rawValue: 0), includingResourceValuesForKeys: nil, relativeTo: nil)
            if currentPicker == .dataDirectory {
                saveDataDirectory(bookmark)
            } else if currentPicker == .configFile {
                saveConfigFile(bookmark)
            }
        } catch let error {
            showError(error.localizedDescription)
        }
        loadContents()

        // FIXME: should ask for a relaunch
    }
}
