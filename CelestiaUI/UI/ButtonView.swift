//
// ButtonView.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaUI
import UIKit

protocol ImageProvider {
    func provideImage() -> UIImage?
    var shouldScaleOnMacCatalyst: Bool { get }
}

struct ImageButtonViewConfiguration<T: ImageProvider>: AutoSizingViewConfiguration {
    func baseSizeForView(_ view: UIView) -> CGSize {
        guard let size = configuration.provideImage()?.size, size.width > 0, size.height > 0 else {
            return boundingBoxSize
        }
        let scaling = configuration.shouldScaleOnMacCatalyst ? GlobalConstants.preferredUIElementScaling(for: view.traitCollection) : 1
        let ratio = min(boundingBoxSize.width / size.width, boundingBoxSize.height / size.height) * scaling
        return CGSize(width: ratio * size.width, height: ratio * size.height)
    }
    var boundingBoxSize: CGSize
    var configuration: T
}

class ImageButtonView<Configuration: ImageProvider>: AutoSizingView<UIButton, ImageButtonViewConfiguration<Configuration>> {
    init(buttonBuilder: @autoclosure () -> UIButton, boundingBoxSize: CGSize, configurationBuilder: @autoclosure () -> Configuration) {
        super.init(viewBuilder: buttonBuilder(), configuration: ImageButtonViewConfiguration(boundingBoxSize: boundingBoxSize, configuration: configurationBuilder()))
    }

    override func apply(_ configuration: ImageButtonViewConfiguration<Configuration>, view: UIButton) {
        view.setImage(configuration.configuration.provideImage(), for: .normal)
        configurationUpdated(configuration.configuration, button: view)
        super.apply(configuration, view: view)
    }

    func configurationUpdated(_ configuration: Configuration, button: UIButton) {}
}
