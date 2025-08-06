// FontSettingViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

struct DisplayFont: Sendable {
    let font: CustomFont
    let name: String
}

public struct CustomFont: Codable, Sendable {
    public let path: String
    public let ttcIndex: Int

    public init(path: String, ttcIndex: Int) {
        self.path = path
        self.ttcIndex = ttcIndex
    }
}

final class FontSettingViewController: BaseTableViewController {
    private let userDefaults: UserDefaults
    private let normalFontPathKey: String
    private let normalFontIndexKey: String
    private let boldFontPathKey: String
    private let boldFontIndexKey: String
    private let customFonts: [DisplayFont]
    private var isBold = false

    private var normalFont: CustomFont?
    private var boldFont: CustomFont?

    private class SegmentedHeader: UITableViewHeaderFooterView {
        private lazy var segmentedControl = UISegmentedControl()
        private var ignoreChanges = false
        var isBold = false {
            didSet {
                if ignoreChanges || isBold == oldValue { return }
                segmentedControl.selectedSegmentIndex = isBold ? 1 : 0
            }
        }
        var selectionChange: ((Bool) -> Void)?

        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)
            setUp()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setUp() {
            segmentedControl.insertSegment(withTitle: CelestiaString("Normal", comment: "Normal font style"), at: segmentedControl.numberOfSegments, animated: false)
            segmentedControl.insertSegment(withTitle: CelestiaString("Bold", comment: "Bold font style"), at: segmentedControl.numberOfSegments, animated: false)
            contentView.addSubview(segmentedControl)
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            segmentedControl.selectedSegmentIndex = isBold ? 1 : 0
            segmentedControl.addTarget(self, action: #selector(segmentedControlSelectionChanged), for: .valueChanged)
            NSLayoutConstraint.activate([
                segmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
                segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                segmentedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -GlobalConstants.listItemMediumMarginVertical),
                segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])
        }

        @objc private func segmentedControlSelectionChanged() {
            let oldValue = isBold
            let newValue = segmentedControl.selectedSegmentIndex == 1
            guard oldValue != newValue else { return }
            ignoreChanges = true
            isBold = newValue
            ignoreChanges = false
            selectionChange?(newValue)
        }
    }

    init(userDefaults: UserDefaults, normalFontPathKey: String, normalFontIndexKey: String, boldFontPathKey: String, boldFontIndexKey: String, customFonts: [DisplayFont]) {
        self.userDefaults = userDefaults
        self.normalFontPathKey = normalFontPathKey
        self.normalFontIndexKey = normalFontIndexKey
        self.boldFontPathKey = boldFontPathKey
        self.boldFontIndexKey = boldFontIndexKey
        self.customFonts = customFonts
        super.init(style: .defaultGrouped)

        if let normalFontPath = userDefaults.string(forKey: normalFontPathKey) {
            let normalFontIndex = userDefaults.integer(forKey: normalFontIndexKey)
            normalFont = CustomFont(path: normalFontPath, ttcIndex: normalFontIndex)
        }
        if let boldFontPath = userDefaults.string(forKey: boldFontPathKey) {
            let boldFontIndex = userDefaults.integer(forKey: boldFontIndexKey)
            boldFont = CustomFont(path: boldFontPath, ttcIndex: boldFontIndex)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(SegmentedHeader.self, forHeaderFooterViewReuseIdentifier: "Header")
        tableView.register(TextCell.self, forCellReuseIdentifier: "Cell")
    }
}

extension FontSettingViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return customFonts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TextCell
        let current = isBold ? boldFont : normalFont
        if indexPath.section == 0 {
            cell.title = CelestiaString("Default", comment: "")
            cell.accessoryType = current == nil ? .checkmark : .none
        } else {
            let font = customFonts[indexPath.row]
            cell.title = font.name
            cell.accessoryType = (current?.path == font.font.path && current?.ttcIndex == font.font.ttcIndex) ? .checkmark : .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as! SegmentedHeader
            header.isBold = isBold
            header.selectionChange = { [weak self] isBold in
                guard let self else { return }
                self.isBold = isBold
                self.tableView.reloadData()
            }
            return header
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return CelestiaString("Configuration will take effect after a restart.", comment: "Change requires a restart")
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let font = indexPath.section != 0 ? customFonts[indexPath.row] : nil
        if isBold {
            boldFont = font?.font
            userDefaults.setValue(font?.font.path, forKey: boldFontPathKey)
            userDefaults.setValue(font?.font.ttcIndex, forKey: boldFontIndexKey)
        } else {
            normalFont = font?.font
            userDefaults.setValue(font?.font.path, forKey: normalFontPathKey)
            userDefaults.setValue(font?.font.ttcIndex, forKey: normalFontIndexKey)
        }
        tableView.reloadData()
    }
}
