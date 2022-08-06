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

protocol AutoSizingViewConfiguration {
    func baseSizeForView(_ view: UIView) -> CGSize
}

class AutoSizingView<View: UIView, Configuration: AutoSizingViewConfiguration>: UIView {
    private let view: View

    var configuration: Configuration {
        didSet {
            apply(configuration, view: view)
        }
    }

    init(viewBuilder: @autoclosure () -> View, configuration: Configuration) {
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            invalidateIntrinsicContentSize()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ configuration: Configuration, view: View) {
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        let scaling = textScaling
        return configuration.baseSizeForView(view).applying(CGAffineTransform(scaleX: scaling, y: scaling))
    }
}

class AnyAutoSizingView: AutoSizingView<UIView, AnyAutoSizingView.Configuration> {
    struct Configuration: AutoSizingViewConfiguration {
        var baseSize: CGSize

        func baseSizeForView(_ view: UIView) -> CGSize {
            return baseSize
        }
    }

    init(viewBuilder: @autoclosure () -> UIView, baseSize: CGSize) {
        super.init(viewBuilder: viewBuilder(), configuration: Configuration(baseSize: baseSize))
    }
}
