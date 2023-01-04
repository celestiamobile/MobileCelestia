//
// TimelineSlider.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

final class TimelineSlider: UIControl {
    var valueFrom: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    var valueTo: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    var value: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    var ticks: [CGFloat] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    var tickLength: CGFloat = GlobalConstants.timeSliderViewDefaultTickLength {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.masksToBounds = true
        layer.cornerCurve = .continuous
        reconfigure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        layer.masksToBounds = true
        layer.cornerCurve = .continuous
        reconfigure()
    }

    private func reconfigure() {
        layer.cornerRadius = bounds.height / 2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        reconfigure()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setNeedsDisplay()
        }
    }

    private func changeViewLocation(to point: CGPoint) {
        var normalized = bounds.width == 0 ? 0 : point.x / bounds.width
        if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
            normalized = 1 - normalized
        }
        normalized = min(1.0, max(0.0, normalized))
        value = normalized * (valueTo - valueFrom) + valueFrom
        sendActions(for: .valueChanged)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        changeViewLocation(to: touch.location(in: self))
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        changeViewLocation(to: touch.location(in: self))
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if let touch {
            changeViewLocation(to: touch.location(in: self))
        }
    }

    private func drawTrack(to: CGFloat, isRTL: Bool, color: UIColor) {
        color.setStroke()
        let width = bounds.width
        let height = bounds.height
        let yCenter = bounds.midY
        var currentX = isRTL ? width : 0
        for tick in ticks {
            if tick > to { break }
            let normalized = normalizeValue(tick)
            let nextX = isRTL ? (1 - normalized) * width : normalized * width
            if isRTL {
                if currentX > nextX + tickLength / 2 {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: currentX, y: yCenter))
                    path.addLine(to: CGPoint(x: nextX + tickLength / 2, y: yCenter))
                    path.lineWidth = height
                    path.stroke()
                    currentX = nextX - tickLength / 2
                }
            } else {
                if currentX < nextX - tickLength / 2 {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: currentX, y: yCenter))
                    path.addLine(to: CGPoint(x: nextX - tickLength / 2, y: yCenter))
                    path.lineWidth = height
                    path.stroke()
                    currentX = nextX + tickLength / 2
                }
            }
        }

        let normalizedLast = normalizeValue(to)
        let lastX = isRTL ? (1 - normalizedLast) * width : normalizedLast * width
        if (isRTL) {
            if currentX > lastX + tickLength / 2 {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: currentX, y: yCenter))
                path.addLine(to: CGPoint(x: lastX + tickLength / 2, y: yCenter))
                path.lineWidth = height
                path.stroke()
            }
        } else {
            if currentX < lastX - tickLength / 2 {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: currentX, y: yCenter))
                path.addLine(to: CGPoint(x: lastX - tickLength / 2, y: yCenter))
                path.lineWidth = height
                path.stroke()
            }
        }
    }

    private func normalizeValue(_ value: CGFloat) -> CGFloat {
        if valueTo == valueFrom { return 0 }
        return (value - valueFrom) / (valueTo - valueFrom)
    }

    override func draw(_ rect: CGRect) {
        UIGraphicsGetCurrentContext()?.clear(bounds)
        let foregroundColor = tintColor.resolvedColor(with: traitCollection)
        let backgroundColor = UIColor.tertiaryLabel.resolvedColor(with: traitCollection)
        let isRTL = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
        drawTrack(to: valueTo, isRTL: isRTL, color: backgroundColor)
        drawTrack(to: value, isRTL: isRTL, color: foregroundColor)
    }
}
