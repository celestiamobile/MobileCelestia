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

public class ProgressButton: UIButton {
    private var progress: CGFloat = 0.0

    private let progressLayer = CALayer()

    override public init(frame: CGRect) {
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

    override public func layoutSubviews() {
        super.layoutSubviews()

        progressLayer.frame = CGRect(x: 0, y: 0, width: bounds.width * progress, height: bounds.height)

        titleLabel?.frame = self.bounds
    }

    public func setProgress(progress: CGFloat) {
        self.progress = progress
        setNeedsLayout()
    }

    public func setBackgroundColor(color: UIColor) {
        self.backgroundColor = color
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.05) {
            self.alpha = 0.85
        }
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()

        #if targetEnvironment(macCatalyst)
        progressLayer.backgroundColor = tintColor.cgColor
        backgroundColor = tintColor.withAlphaComponent(0.5)
        #endif
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
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

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
}
