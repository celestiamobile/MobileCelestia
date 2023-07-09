//
// AutoSizingView.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

@MainActor
public protocol AutoSizingViewConfiguration {
    func baseSizeForView(_ view: UIView) -> CGSize
}

open class AutoSizingView<View: UIView, Configuration: AutoSizingViewConfiguration>: UIView {
    private let view: View

    public var configuration: Configuration {
        didSet {
            apply(configuration, view: view)
        }
    }

    public init(viewBuilder: @autoclosure () -> View, configuration: Configuration) {
        self.configuration = configuration
        self.view = viewBuilder()
        super.init(frame: .zero)

        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        apply(configuration, view: view)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            invalidateIntrinsicContentSize()
        }
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func apply(_ configuration: Configuration, view: View) {
        invalidateIntrinsicContentSize()
    }

    public override var intrinsicContentSize: CGSize {
        let scaling = textScaling
        return configuration.baseSizeForView(view).applying(CGAffineTransform(scaleX: scaling, y: scaling))
    }
}

public class AnyAutoSizingView: AutoSizingView<UIView, AnyAutoSizingView.Configuration> {
    public struct Configuration: AutoSizingViewConfiguration {
        var baseSize: CGSize

        public init(baseSize: CGSize) {
            self.baseSize = baseSize
        }

        public func baseSizeForView(_ view: UIView) -> CGSize {
            return baseSize
        }
    }

    public init(viewBuilder: @autoclosure () -> UIView, baseSize: CGSize) {
        super.init(viewBuilder: viewBuilder(), configuration: Configuration(baseSize: baseSize))
    }
}
