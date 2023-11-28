//
// SelectionCell.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

@available(iOS 15.0, *)
public class SelectionCell: UITableViewCell {
    private lazy var label = UILabel(textStyle: .body)
    private lazy var subtitleLabel = UILabel(textStyle: .footnote)
    private lazy var button: UIButton = {
#if targetEnvironment(macCatalyst)
        return UIButton(type: .system)
#else
        return UIButton(configuration: .plain())
#endif
    }()

    public var title: String? { didSet { label.text = title }  }
    public var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = subtitle == nil
        }
    }

    public var selectionData = SelectionData(options: [], selectedIndex: -1) {
        didSet {
            reloadMenu()
        }
    }

    public struct SelectionData {
        let options: [String]
        let selectedIndex: Int

        public init(options: [String], selectedIndex: Int) {
            self.options = options
            self.selectedIndex = selectedIndex
        }
    }

    public var selectionChange: ((Int) -> Void)?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setUp()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 15.0, *)
private extension SelectionCell {
    func setUp() {
        selectionStyle = .none

        label.textColor = .label
        label.numberOfLines = 0
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.isHidden = true

        let stackView = UIStackView(arrangedSubviews: [label, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = GlobalConstants.listTextGapVertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
        ])

        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: GlobalConstants.listItemGapHorizontal),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -GlobalConstants.listItemPopUpButtonMarginHorizontal),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            button.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: GlobalConstants.listItemAccessoryMinMarginVertical),
        ])

        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func reloadMenu() {
        let actions = selectionData.options.enumerated().map { (index, title) in
            return UIAction(title: title, state: index == selectionData.selectedIndex ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.selectionChange?(index)
            }
        }
        button.menu = UIMenu(children: actions)
    }
}

