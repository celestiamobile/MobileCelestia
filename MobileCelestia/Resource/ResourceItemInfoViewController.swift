//
// ResourceItemInfoViewController.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

import SDWebImage

class ResourceItemInfoViewController: UIViewController {
    private var item: ResourceItem

    private lazy var scrollView = UIScrollView(frame: .zero)
    private lazy var authorsLabel = UILabel()
    private lazy var releaseDateLabel = UILabel()
    private lazy var descriptionLabel = UILabel()
    private lazy var imageView = UIImageView()
    private lazy var footnoteLabel = UILabel()

    private lazy var contentStack = UIStackView(arrangedSubviews: [
        authorsLabel,
        releaseDateLabel,
        descriptionLabel,
        imageView,
        footnoteLabel
    ])

    private var aspectRatioConstraint: NSLayoutConstraint?

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    init(item: ResourceItem) {
        // Store to cache key dictionary
        if let imageURL = item.image {
            let manager = ImageCacheManager.shared
            manager.save(url: imageURL.absoluteString, id: item.id)
        }
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = scrollView
        view.backgroundColor = .darkBackground

        setup()
    }

    func update(item: ResourceItem) {
        self.item = item
        updateContents()
    }
}

private extension ResourceItemInfoViewController {
    func setup() {
        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentContainer)
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentContainer.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant:  -32)
        ])

        contentContainer.backgroundColor = .clear

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 4
        contentStack.setCustomSpacing(8, after: descriptionLabel)
        contentStack.setCustomSpacing(8, after: imageView)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
        ])

        authorsLabel.numberOfLines = 0
        authorsLabel.textColor = .darkSecondaryLabel
        authorsLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        releaseDateLabel.numberOfLines = 0
        releaseDateLabel.textColor = .darkSecondaryLabel
        releaseDateLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .darkSecondaryLabel
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)

        imageView.isHidden = true

        footnoteLabel.text = CelestiaString("Note: restarting Celestia is needed to use any new installed add-on.", comment: "")
        footnoteLabel.numberOfLines = 0
        footnoteLabel.textColor = .darkSecondaryLabel
        footnoteLabel.font = UIFont.preferredFont(forTextStyle: .footnote)

        updateContents()
    }

    private func updateContents() {
        descriptionLabel.text = item.description
        imageView.sd_cancelCurrentImageLoad()
        if let imageURL = item.image {
            imageView.sd_setImage(with: imageURL) { [weak self] image, _, _, _ in
                guard let self = self else { return }
                guard let size = image?.size else {
                    self.imageView.image = nil
                    self.imageView.isHidden = true
                    self.aspectRatioConstraint?.isActive = false
                    self.aspectRatioConstraint = nil
                    return
                }
                self.imageView.isHidden = false
                self.aspectRatioConstraint?.isActive = false
                self.aspectRatioConstraint = self.imageView.heightAnchor.constraint(equalTo: self.imageView.widthAnchor, multiplier: size.height / size.width)
                self.aspectRatioConstraint?.isActive = true
            }
        } else {
            imageView.isHidden = true
            imageView.image = nil
            aspectRatioConstraint?.isActive = false
            aspectRatioConstraint = nil
        }
        if let releaseDate = item.publishTime {
            releaseDateLabel.isHidden = false
            releaseDateLabel.text = String(format: CelestiaString("Release date: %s", comment: "").toLocalizationTemplate, dateFormatter.string(from: releaseDate))
        } else {
            releaseDateLabel.isHidden = true
        }
        if let authors = item.authors, authors.count > 0 {
            authorsLabel.isHidden = false
            let template = CelestiaString("Authors: %s", comment: "").toLocalizationTemplate
            if #available(iOS 13, *) {
                authorsLabel.text = String(format: template, ListFormatter.localizedString(byJoining: authors))
            } else {
                authorsLabel.text = String(format: template, authors.joined(separator: ", "))
            }
        } else {
            authorsLabel.isHidden = true
        }
    }
}

