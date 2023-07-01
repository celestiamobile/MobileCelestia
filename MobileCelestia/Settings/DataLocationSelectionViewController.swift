//
// DataLocationSelectionViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

class DataLocationSelectionViewController: BaseTableViewController {
    @Injected(\.userDefaults) private var userDefaults
    private var items: [[TextItem]] = []

    private enum Location: Int {
        case dataDirectory
        case configFile
    }

    private var currentPicker: Location?

    init() {
        super.init(style: .defaultGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
                           detail: userDefaults.currentDataDirectory().url == UserDefaults.defaultDataDirectory ? CelestiaString("Default", comment: "") : CelestiaString("Custom", comment: "")),
            TextItem.short(title: CelestiaString("Config File", comment: ""),
                           detail: userDefaults.currentConfigFile().url == UserDefaults.defaultConfigFile ? CelestiaString("Default", comment: "") : CelestiaString("Custom", comment: "")),
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
        tableView.register(SettingTextCell.self, forCellReuseIdentifier: "Text")
        title = CelestiaString("Data Location", comment: "")
    }
}

extension DataLocationSelectionViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            userDefaults.saveDataDirectory(nil)
            userDefaults.saveConfigFile(nil)

            loadContents()
        } else {
            let browser: UIDocumentPickerViewController
            if #available(iOS 14, *) {
                let types = [UTType.folder, UTType.data]
                browser = UIDocumentPickerViewController(forOpeningContentTypes: [types[indexPath.row]])
            } else {
                let types = [kUTTypeFolder as String, kUTTypeData as String]
                browser = UIDocumentPickerViewController(documentTypes: [types[indexPath.row]], in: .open)
            }
            currentPicker = Location(rawValue: indexPath.row)
            browser.allowsMultipleSelection = false
            browser.delegate = self
            present(browser, animated: true, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return CelestiaString("Configuration will take effect after a restart.", comment: "")
        }
        return nil
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
            #if targetEnvironment(macCatalyst)
            let bookmark = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
            #else
            let bookmark = try url.bookmarkData(options: .init(rawValue: 0), includingResourceValuesForKeys: nil, relativeTo: nil)
            #endif
            if currentPicker == .dataDirectory {
                userDefaults.saveDataDirectory(bookmark)
            } else if currentPicker == .configFile {
                userDefaults.saveConfigFile(bookmark)
            }
        } catch let error {
            showError(error.localizedDescription)
        }
        loadContents()

        // FIXME: should ask for a relaunch
    }
}
