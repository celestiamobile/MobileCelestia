//
// SegmentedControlConfiguration.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

struct SegmentedControlConfiguration: UIContentConfiguration {
    let segmentTitles: [String]
    let selectedSegmentIndex: Int
    let selectedIndexChanged: (Int) -> Void

    func makeContentView() -> UIView & UIContentView {
        return SegmentedControlView(configuration: self)
    }

    func updated(for state: any UIConfigurationState) -> SegmentedControlConfiguration {
        self
    }
}

class SegmentedControlView: UIView, UIContentView {
    private lazy var segmentedControl = UISegmentedControl()

    var currentConfiguration: SegmentedControlConfiguration!

    var configuration: UIContentConfiguration {
        get {
            currentConfiguration!
        }
        set {
            guard let newConfiguration = newValue as? SegmentedControlConfiguration else {
                return
            }
            apply(configuration: newConfiguration)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: topAnchor, constant: GlobalConstants.listItemMediumMarginVertical),
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -GlobalConstants.listItemMediumMarginVertical),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        segmentedControl.addTarget(self, action: #selector(segmentedControlSelectionChanged), for: .valueChanged)
    }

    init(configuration: SegmentedControlConfiguration) {
        super.init(frame: .zero)

        setUp()
        apply(configuration: configuration)
    }

    private func apply(configuration: SegmentedControlConfiguration) {
        currentConfiguration = configuration

        segmentedControl.removeAllSegments()
        for (index, title) in configuration.segmentTitles.enumerated() {
            segmentedControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        segmentedControl.selectedSegmentIndex = configuration.selectedSegmentIndex
    }

    @objc private func segmentedControlSelectionChanged() {
        currentConfiguration.selectedIndexChanged(segmentedControl.selectedSegmentIndex)
    }
}
