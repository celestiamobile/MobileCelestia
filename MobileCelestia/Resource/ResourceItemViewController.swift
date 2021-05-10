//
// ResourceItemViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

import SDWebImage
import CelestiaCore

class ResourceItemViewController: UIViewController {
    class ImageCacheManager {
        static let shared: ImageCacheManager = ImageCacheManager()
        private var cacheKeyDictionary: [String: String] = [:]

        private init() {
            SDWebImageManager.shared.cacheKeyFilter = SDWebImageCacheKeyFilter(block: { [weak self] url in
                return self?.cacheKeyDictionary[url.absoluteString] ?? url.absoluteString
            })
        }

        func save(url: String, id: String) {
            cacheKeyDictionary[url] = id
        }
    }

    enum ResourceItemState {
        case none
        case downloading
        case installed
    }

    private var item: ResourceItem

    private lazy var scrollView = UIScrollView(frame: .zero)
    private lazy var progressButton = ProgressButton(frame: .zero)

    private lazy var titleLabel = UILabel()
    private lazy var authorsLabel = UILabel()
    private lazy var releaseDateLabel = UILabel()
    private lazy var descriptionLabel = UILabel()
    private lazy var imageView = UIImageView()
    private lazy var footnoteLabel = UILabel()

    private lazy var contentStack = UIStackView(arrangedSubviews: [
        titleLabel,
        authorsLabel,
        releaseDateLabel,
        descriptionLabel,
        imageView,
        footnoteLabel
    ])

    private var aspectRatioConstraint: NSLayoutConstraint?

    private var currentState: ResourceItemState = .none

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
        view = UIView()
        view.backgroundColor = .darkBackground

        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()

        NotificationCenter.default.addObserver(self, selector: #selector(downloadProgress(_:)), name: ResourceManager.downloadProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resourceFetchError(_:)), name: ResourceManager.resourceError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadSuccess(_:)), name: ResourceManager.downloadSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unzipSuccess(_:)), name: ResourceManager.unzipSuccess, object: nil)

        refresh()
    }

    private func refresh() {
        // Fetch the latest item, this is needed as user might come
        // here from Installed where the URL might be incorrect
        let requestURL = apiPrefix + "/resource/item"
        let locale = LocalizedString("LANGUAGE", "celestia")
        _ = RequestHandler.get(url: requestURL, parameters: ["lang": locale, "item": item.id], success: { [weak self] (item: ResourceItem) in
            self?.item = item
            self?.updateContents()
        }, decoder: ResourceItem.networkResponseDecoder)
    }

    @objc private func progressButtonClicked() {
        let dm = ResourceManager.shared

        if dm.isInstalled(identifier: item.id) {
            // Already installed, offer option for uninstalling
            showOption(CelestiaString("Do you want to uninstall this add-on?", comment: "")) { [weak self] confirm in
                guard let self = self else { return }
                do {
                    try dm.uninstall(identifier: self.item.id)
                    self.currentState = .none
                } catch {
                    self.showError(CelestiaString("Unable to uninstall add-on.", comment: ""))
                }
                self.updateUI()
            }
            return
        }

        // Cancel if already downloading
        if dm.isDownloading(identifier: item.id) {
            showOption(CelestiaString("Do you want to cancel this task?", comment: "")) { [weak self] confirm in
                guard confirm, let self = self, dm.isDownloading(identifier: self.item.id) else { return }
                dm.cancel(identifier: self.item.id)
                self.currentState = .none
                self.updateUI()
            }
            return
        }

        // Download
        dm.download(item: item)
        currentState = .downloading
        updateUI()
    }
}

private extension ResourceItemViewController {
    func setup() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

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

        titleLabel.numberOfLines = 0
        titleLabel.textColor = .darkLabel
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
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

        let ratio: CGFloat
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            ratio = 0.77
        } else {
            ratio = 1.0
        }

        progressButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressButton)
        NSLayoutConstraint.activate([
            progressButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12),
            progressButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            progressButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            progressButton.heightAnchor.constraint(equalToConstant: 40 * ratio)
        ])
        progressButton.addTarget(self, action: #selector(progressButtonClicked), for: .touchUpInside)

        updateContents()
    }

    private func updateContents() {
        titleLabel.text = item.name
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

    private func updateUI() {
        let dm = ResourceManager.shared
        if dm.isInstalled(identifier: item.id) {
            currentState = .installed
        }
        if dm.isDownloading(identifier: item.id) {
            currentState = .downloading
        }

        // TODO: Localization
        switch currentState {
        case .none:
            progressButton.resetProgress()
            progressButton.setTitle(CelestiaString("DOWNLOAD", comment: ""), for: .normal)
        case .downloading:
            progressButton.setTitle(CelestiaString("DOWNLOADING", comment: ""), for: .normal)
        case .installed:
            progressButton.setProgress(progress: 1.0)
            progressButton.setTitle(CelestiaString("INSTALLED", comment: ""), for: .normal)
        }
    }
}

private extension ResourceItemViewController {
    @objc private func downloadProgress(_ notification: Notification) {
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == item.id else {
            return
        }

        guard let progress = notification.userInfo?[ResourceManager.downloadProgressKey] as? Double else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.progressButton.setProgress(progress: CGFloat(progress))
            self?.updateUI()
        }
    }

    @objc private func downloadSuccess(_ notification: Notification) {
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == item.id else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.updateUI()
        }
    }

    @objc private func resourceFetchError(_ notification: Notification) {
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == item.id else {
            return
        }
        guard let error = notification.userInfo?[ResourceManager.resourceErrorKey] as? Error else {
            return
        }
        currentState = .none
        DispatchQueue.main.async { [weak self] in
            self?.updateUI()
            self?.showError(error.localizedDescription)
        }
    }

    @objc private func unzipSuccess(_ notification: Notification) {
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == item.id else {
            return
        }
        currentState = .installed
        DispatchQueue.main.async { [weak self] in
            self?.updateUI()
        }
    }
}
