// IconView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import UIKit

public class IconView: AutoSizingView<UIImageView, IconView.Configuration> {
    private lazy var imageView = UIImageView()

    public struct Configuration: AutoSizingViewConfiguration {
        public func baseSizeForView(_ view: UIView) -> CGSize {
            return baseSize
        }

        public var image: UIImage?
        var baseSize: CGSize

        init(image: UIImage?, baseSize: CGSize) {
            self.image = image
            self.baseSize = baseSize
        }
    }

    public init(image: UIImage? = nil, baseSize: CGSize, configuration: ((UIImageView) -> Void)? = nil) {
        super.init(viewBuilder: {
            let imageView = UIImageView()
            configuration?(imageView)
            return imageView
        }(), configuration: Configuration(image: image, baseSize: baseSize))
    }

    public override func apply(_ configuration: Configuration, view: UIImageView) {
        view.image = configuration.image
        super.apply(configuration, view: view)
    }
}
