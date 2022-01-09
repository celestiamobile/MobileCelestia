//
// ProgressButton.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

class ProgressButton: StandardButton {
    private var progress: CGFloat = 0.0

    private let progressLayer = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.masksToBounds = true

        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center

        #if targetEnvironment(macCatalyst)
        progressLayer.backgroundColor = tintColor.cgColor
        backgroundColor = tintColor.withAlphaComponent(0.5)
        #else
        progressLayer.backgroundColor = UIColor.progressForeground.cgColor
        backgroundColor = UIColor.progressBackground
        #endif

        setTitleColor(.white, for: .normal)

        layer.addSublayer(progressLayer)
        bringSubviewToFront(titleLabel!)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func resetProgress() {
        self.setProgress(progress: 0.0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
            progressLayer.frame = CGRect(x: bounds.width * (1 - progress), y: 0, width: bounds.width * progress, height: bounds.height)
        } else {
            progressLayer.frame = CGRect(x: 0, y: 0, width: bounds.width * progress, height: bounds.height)
        }

        titleLabel?.frame = self.bounds
    }

    func setProgress(progress: CGFloat) {
        self.progress = progress
        setNeedsLayout()
    }

    func setBackgroundColor(color: UIColor) {
        self.backgroundColor = color
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        #if targetEnvironment(macCatalyst)
        progressLayer.backgroundColor = tintColor.cgColor
        backgroundColor = tintColor.withAlphaComponent(0.5)
        #endif
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return
        }

        #if targetEnvironment(macCatalyst)
        progressLayer.backgroundColor = tintColor.cgColor
        backgroundColor = tintColor.withAlphaComponent(0.5)
        #else
        progressLayer.backgroundColor = UIColor.progressForeground.cgColor
        backgroundColor = UIColor.progressBackground
        #endif
    }
}
