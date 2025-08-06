// ICPCFooter.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#if !targetEnvironment(macCatalyst)
import UIKit

final class ICPCFooter: UITableViewHeaderFooterView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setUp()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUp() {
        let button = UIButton(type: .system)
        button.setTitle("苏ICP备2023039249号-4A", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GlobalConstants.listItemMediumMarginHorizontal),
            button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    @objc private func handleButtonTap() {
        guard let url = URL(string: "https://beian.miit.gov.cn") else { return }
        UIApplication.shared.open(url)
    }
}
#endif
