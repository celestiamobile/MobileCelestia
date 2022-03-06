//
// StylizedResourceCell.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import SDWebImage
import UIKit

final class StylizedResourceCell: UITableViewCell {
    private class GradientView: UIView {
        private lazy var gradientLayer = CAGradientLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)

            gradientLayer.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.withAlphaComponent(0.5).cgColor]
            gradientLayer.locations = [0.0, 1.0]
            gradientLayer.frame = bounds
            layer.insertSublayer(gradientLayer, at: 0)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            gradientLayer.frame = bounds
        }
    }

    enum Constants {
        static let horizontalMargin: CGFloat = 16
        static let verticalMargin: CGFloat = 8
        static let textHorizontalMargin: CGFloat = 12
        static let textVerticalMargin: CGFloat = 8
        static let contentAspectRatio: CGFloat = 3
    }

    private lazy var label = UILabel(textStyle: .title3, weight: .semibold)
    private lazy var backgroundImageView = UIImageView(image: UIImage(named: "resource_item_placeholder"))

    var title: String? { didSet { label.text = title }  }
    var imageURL: (URL, String)? {
        didSet {
            if let (url, key) = imageURL {
                backgroundImageView.sd_cancelCurrentImageLoad()
                ImageCacheManager.shared.save(url: url.absoluteString, id: key)
                backgroundImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "resource_item_placeholder"))
            } else {
                backgroundImageView.sd_cancelCurrentImageLoad()
                backgroundImageView.image = UIImage(named: "resource_item_placeholder")
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        label.text = nil
        label.textColor = .darkLabel
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension StylizedResourceCell {
    func setup() {
        if #available(iOS 13.0, *) {
        } else {
            backgroundColor = .darkBackground
        }
        selectionStyle = .none

        let containerView = UIView()
        containerView.backgroundColor = .green
        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = 8
        if #available(iOS 13, *) {
            containerView.layer.cornerCurve = .continuous
        }
        containerView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.verticalMargin),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.verticalMargin),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalMargin),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalMargin),
            containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: Constants.contentAspectRatio),
        ])

        containerView.addSubview(backgroundImageView)

        let textContainerView = GradientView()
        textContainerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(textContainerView)
        NSLayoutConstraint.activate([
            textContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textContainerView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.5),
            textContainerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        label.textColor = .darkLabel
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0

        label.translatesAutoresizingMaskIntoConstraints = false
        textContainerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: textContainerView.leadingAnchor, constant: Constants.textHorizontalMargin),
            label.trailingAnchor.constraint(equalTo: textContainerView.trailingAnchor, constant: -Constants.textHorizontalMargin),
            label.topAnchor.constraint(greaterThanOrEqualTo: textContainerView.topAnchor, constant: -Constants.textVerticalMargin),
            label.bottomAnchor.constraint(equalTo: textContainerView.bottomAnchor, constant: -Constants.textVerticalMargin),
        ])
    }
}
