//
// ResourceItemListViewController.swift
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
    private lazy var descriptionLabel = UILabel()
    private lazy var imageView = UIImageView()
    private var aspectRatioConstraint: NSLayoutConstraint?

    private var currentState: ResourceItemState = .none

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
        _ = RequestHandler.get(url: requestURL, params: ["lang": locale, "item": item.id], success: { [weak self] (item: ResourceItem) in
            self?.item = item
            self?.updateContents()
        })
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
            // TODO: Localization
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

        titleLabel.numberOfLines = 0
        titleLabel.textColor = .darkLabel
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
        ])

        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .darkSecondaryLabel
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
        ])

        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
        ])
        aspectRatioConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0)

        let footnoteLabel = UILabel()
        // TODO: Localization
        footnoteLabel.text = CelestiaString("Note: restarting Celestia is needed to use any new installed add-on.", comment: "")
        footnoteLabel.numberOfLines = 0
        footnoteLabel.textColor = .darkSecondaryLabel
        footnoteLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        footnoteLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(footnoteLabel)
        NSLayoutConstraint.activate([
            footnoteLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            footnoteLabel.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            footnoteLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            footnoteLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
        ])

        progressButton.translatesAutoresizingMaskIntoConstraints = false
        progressButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(progressButton)
        NSLayoutConstraint.activate([
            progressButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
            progressButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            progressButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            progressButton.heightAnchor.constraint(equalToConstant: 40)
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
                guard let size = image?.size, let self = self else { return }
                self.aspectRatioConstraint?.isActive = false
                self.aspectRatioConstraint = self.imageView.heightAnchor.constraint(equalTo: self.imageView.widthAnchor, multiplier: size.height / size.width)
                self.aspectRatioConstraint?.isActive = true
            }
        } else {
            imageView.image = nil
            self.aspectRatioConstraint?.isActive = false
            self.aspectRatioConstraint = self.imageView.heightAnchor.constraint(equalTo: self.imageView.widthAnchor, multiplier: 0)
            self.aspectRatioConstraint?.isActive = true
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
