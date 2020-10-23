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
    private let cornerRadius: CGFloat = 5
    private var progress: CGFloat = 0.0

    private let progressLayer = CALayer()
    private var progressColor = UIColor.progressForeground

    override public init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        backgroundColor = UIColor.progressBackground

        titleLabel?.textAlignment = .center
        titleLabel?.textColor = .white
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 0)

        progressLayer.backgroundColor = UIColor.progressForeground.cgColor

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
        titleLabel?.font = titleLabel?.font.withSize(titleLabel!.frame.height * 0.45)
    }

    public func setProgress(progress: CGFloat) {
        self.progress = progress
        setNeedsLayout()
    }

    public func setProgressColor(color: UIColor) {
        self.progressColor = color
        self.progressLayer.backgroundColor = color.cgColor
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

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
}
