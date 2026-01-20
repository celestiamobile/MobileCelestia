//
// ScaledPortalView.swift
//
// Copyright © 2026 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

final class ScaledPortalView: UIView {
    private var sourceViewBoundsObservation: NSKeyValueObservation?
    private var portalViewBoundsObservation: NSKeyValueObservation?

    private let sourceView: UIView
    private let portalView: UIView

    private static var portalViewClass = NSClassFromString("_UIPortalView") as? NSObject.Type

    static var canBeUsed: Bool = {
        guard let portalViewClass else { return false }
        guard let portalLayerClass = NSClassFromString("CAPortalLayer") as? NSObject.Type else { return false }
        return portalViewClass.instancesRespond(to: NSSelectorFromString("initWithSourceView:")) && portalViewClass.instancesRespond(to: NSSelectorFromString("portalLayer")) && portalLayerClass.instancesRespond(to: NSSelectorFromString("setCrossDisplay:"))
    }()

    init(sourceView: UIView) {
        self.sourceView = sourceView
        let portalViewClass = Self.portalViewClass!
        portalView = portalViewClass.perform(NSSelectorFromString("alloc")).takeUnretainedValue().perform(NSSelectorFromString("initWithSourceView:"), with: sourceView).takeUnretainedValue() as! UIView
        let layer = portalView.value(forKey: "portalLayer") as! CALayer
        layer.setValue(true, forKey: "crossDisplay")

        super.init(frame: .zero)

        portalView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(portalView)
        NSLayoutConstraint.activate([
            portalView.topAnchor.constraint(equalTo: topAnchor),
            portalView.bottomAnchor.constraint(equalTo: bottomAnchor),
            portalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            portalView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        sourceViewBoundsObservation = sourceView.observe(\.bounds) { [weak self] sourceView, _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.sourceView.bounds.width == 0 || self.sourceView.bounds.height == 0 {
                    return
                }
                UIView.performWithoutAnimation {
                    self.invalidateIntrinsicContentSize()
                    self.updatePortalTransform()
                }
            }
        }

        portalViewBoundsObservation = portalView.observe(\.bounds) { [weak self] portalView, _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.sourceView.bounds.width == 0 || self.sourceView.bounds.height == 0 {
                    return
                }
                UIView.performWithoutAnimation {
                    self.updatePortalTransform()
                }
            }
        }
    }

    private func updatePortalTransform() {
        if self.sourceView.bounds.width == 0 || self.sourceView.bounds.height == 0 {
            return
        }
        self.portalView.transform = CGAffineTransform(scaleX: self.portalView.bounds.width / self.sourceView.bounds.width, y: self.portalView.bounds.height / self.sourceView.bounds.height)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        if sourceView.frame.size.width > 0 && sourceView.frame.size.height > 0 {
            return sourceView.frame.size
        }
        return sourceView.intrinsicContentSize
    }
}
