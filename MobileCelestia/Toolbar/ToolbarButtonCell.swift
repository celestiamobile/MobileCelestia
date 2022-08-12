//
// ToolbarButtonCell.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

protocol ToolbarCell: UICollectionViewCell {
    var itemTitle: String? { get set }
    var itemImage: UIImage? { get set }
    var touchDownHandler: ((UIButton) -> Void)? { get set }
    var touchUpHandler: ((UIButton, Bool) -> Void)? { get set }
}

class ToolbarImageButton: ImageButtonView<ToolbarImageButton.Configuration> {
    struct Configuration: ImageProvider {
        var image: UIImage?
        var touchDownHandler: ((UIButton) -> Void)?
        var touchUpHandler: ((UIButton, Bool) -> Void)?

        func provideImage(selected: Bool) -> UIImage? {
            return image
        }
    }

    init(image: UIImage? = nil, touchDownHandler: ((UIButton) -> Void)?, touchUpHandler: ((UIButton, Bool) -> Void)?) {
        super.init(buttonBuilder: {
            let button = StandardButton(type: .system)
            button.imageView?.contentMode = .scaleAspectFit
            button.contentHorizontalAlignment = .fill
            button.contentVerticalAlignment = .fill
            button.tintColor = .darkLabel
            return button
        }(), boundingBoxSize: CGSize(width: GlobalConstants.bottomControlViewItemDimension, height: GlobalConstants.bottomControlViewItemDimension), configurationBuilder: Configuration(image: image, touchDownHandler: touchDownHandler, touchUpHandler: touchUpHandler))
    }

    override func configurationUpdated(_ configuration: Configuration, button: UIButton) {
        super.configurationUpdated(configuration, button: button)
        button.removeTarget(self, action: nil, for: .allEvents)
        button.addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(touchUpOutside(_:)), for: .touchUpOutside)
        button.addTarget(self, action: #selector(touchCancelled(_:)), for: .touchCancel)
    }

    @objc private func touchDown(_ sender: UIButton) {
        configuration.configuration.touchDownHandler?(sender)
    }

    @objc private func touchUpInside(_ sender: UIButton) {
        configuration.configuration.touchUpHandler?(sender, true)
    }


    @objc private func touchUpOutside(_ sender: UIButton) {
        configuration.configuration.touchUpHandler?(sender, false)
    }

    @objc private func touchCancelled(_ sender: UIButton) {
        configuration.configuration.touchUpHandler?(sender, false)
    }
}

class ToolbarImageButtonCell: UICollectionViewCell, ToolbarCell {
    var itemTitle: String?
    var itemImage: UIImage? { didSet { button.configuration.configuration.image = itemImage } }
    var touchDownHandler: ((UIButton) -> Void)?
    var touchUpHandler: ((UIButton, Bool) -> Void)?

    private lazy var button = ToolbarImageButton { [weak self] button in
        self?.touchDownHandler?(button)
    } touchUpHandler: { [weak self] button, inside in
        self?.touchUpHandler?(button, inside)
    }


    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    @objc private func touchDown(_ sender: UIButton) {
        touchDownHandler?(sender)
    }

    @objc private func touchUpInside(_ sender: UIButton) {
        touchUpHandler?(sender, true)
    }


    @objc private func touchUpOutside(_ sender: UIButton) {
        touchUpHandler?(sender, false)
    }

    @objc private func touchCancelled(_ sender: UIButton) {
        touchUpHandler?(sender, false)
    }
}

class ToolbarImageTextButtonCell: UICollectionViewCell, ToolbarCell {
    private enum Constants {
        static let iconDimension: CGFloat = 24
        static let highlightAnimationDuration: TimeInterval = 0.1
        static let unhighlightAnimationDuration: TimeInterval = 0.05
    }

    private class SelectionView: UIControl {
        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = .clear
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            UIView.animate(withDuration: Constants.highlightAnimationDuration) {
                var color = UIColor.darkSelection
                if #available(iOS 13.0, *) {
                    color = color.resolvedColor(with: self.traitCollection)
                }
                self.layer.backgroundColor = color.cgColor
            }
            return true
        }

        override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
            UIView.animate(withDuration: Constants.unhighlightAnimationDuration) {
                self.layer.backgroundColor = UIColor.clear.cgColor
            }
        }

        override func cancelTracking(with event: UIEvent?) {
            layer.backgroundColor = UIColor.clear.cgColor
        }
    }

    var itemTitle: String? { didSet { label.text = itemTitle } }
    var itemImage: UIImage? { didSet { imageView.configuration.image = itemImage?.withRenderingMode(.alwaysTemplate) } }
    var touchDownHandler: ((UIButton) -> Void)?
    var touchUpHandler: ((UIButton, Bool) -> Void)?

    private lazy var imageView: IconView = {
        let dimension = GlobalConstants.preferredUIElementScaling(for: traitCollection) * Constants.iconDimension
        return IconView(baseSize: CGSize(width: dimension, height: dimension)) { imageView in
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .darkLabel
        }
    }()
    private lazy var label = UILabel(textStyle: .body)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let bg = SelectionView(frame: .zero)
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        bg.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        bg.addTarget(self, action: #selector(touchUpOutside(_:)), for: .touchUpOutside)
        bg.addTarget(self, action: #selector(touchCancelled(_:)), for: .touchCancel)

        contentView.addSubview(bg)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: contentView.topAnchor),
            bg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bg.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        bg.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: GlobalConstants.listItemMarginHorizontal),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: bg.topAnchor, constant: GlobalConstants.listItemAccessoryMinMarginVertical),
        ])

        bg.addSubview(label)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: GlobalConstants.listItemMarginVertical),
            label.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -GlobalConstants.listItemMarginHorizontal),
            label.topAnchor.constraint(greaterThanOrEqualTo: bg.topAnchor, constant: GlobalConstants.listItemMarginVertical),
        ])
        label.textColor = .darkLabel
    }

    @objc private func touchDown(_ sender: UIButton) {
        touchDownHandler?(sender)
    }

    @objc private func touchUpInside(_ sender: UIButton) {
        touchUpHandler?(sender, true)
    }


    @objc private func touchUpOutside(_ sender: UIButton) {
        touchUpHandler?(sender, false)
    }

    @objc private func touchCancelled(_ sender: UIButton) {
        touchUpHandler?(sender, false)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let fittingSize = contentView.systemLayoutSizeFitting(
            CGSize(width: layoutAttributes.size.width, height: 0),
            withHorizontalFittingPriority: UILayoutPriority.required,
            verticalFittingPriority: UILayoutPriority.defaultLow)
        attributes.size = CGSize(width: fittingSize.width.rounded(.down), height: fittingSize.height)
        return attributes
    }
}

class ToolbarSeparatorCell: UICollectionViewCell {
    private enum Constants {
        static let separatorInsetLeading: CGFloat = 32
    }

    let sep = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        sep.backgroundColor = .darkSeparator
        sep.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.heightAnchor.constraint(equalToConstant: GlobalConstants.listItemSeparatorHeight),
            sep.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.separatorInsetLeading),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
}
