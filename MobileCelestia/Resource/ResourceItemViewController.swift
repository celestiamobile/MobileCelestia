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
    enum ResourceItemState {
        case none
        case downloading
        case installed
    }

    private var item: ResourceItem

    private lazy var scrollView = UIScrollView(frame: .zero)
    private lazy var progressButton = CompatProgressButton()
    private lazy var goToButton = ActionButton(type: .system)
    private lazy var buttonStack = UIStackView(arrangedSubviews: [goToButton, progressButton])

    private lazy var titleLabel = UILabel()
    private lazy var authorsLabel = UILabel()
    private lazy var releaseDateLabel = UILabel()
    private lazy var descriptionLabel = UILabel()
    private lazy var imageView = UIImageView()
    private lazy var footnoteLabel = UILabel()

    private lazy var topStack = UIStackView(arrangedSubviews: [
        titleLabel,
        authorsLabel,
        releaseDateLabel,
    ])

    private lazy var topContentView: UIView = {
        let view = UIView()
        topStack.translatesAutoresizingMaskIntoConstraints = false
        topStack.axis = .vertical
        topStack.spacing = 4
        view.addSubview(topStack)
        shareButton.setImage(UIImage(named: "share_common_small")?.withRenderingMode(.alwaysTemplate), for: .normal)
        shareButton.tintColor = .darkLabel
        shareButton.setContentHuggingPriority(.required, for: .horizontal)
        shareButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shareButton)
        NSLayoutConstraint.activate([
            topStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topStack.topAnchor.constraint(equalTo: view.topAnchor),
            topStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shareButton.topAnchor.constraint(equalTo: view.topAnchor),
            shareButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            topStack.trailingAnchor.constraint(equalTo: shareButton.leadingAnchor, constant: -8),
        ])
        return view
    }()

    private lazy var shareButton = StandardButton()

    private lazy var contentStack = UIStackView(arrangedSubviews: [
        topContentView,
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

        shareButton.addTarget(self, action: #selector(showShare(_:)), for: .touchUpInside)

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

    @objc private func showShare(_ sender: UIButton) {
        let baseURL = "https://celestia.mobi/resources/item"
        let locale = LocalizedString("LANGUAGE", "celestia")
        guard var components = URLComponents(string: baseURL) else { return }
        components.queryItems = [URLQueryItem(name: "item", value: item.id), URLQueryItem(name: "lang", value: locale)]
        guard let url = components.url else { return }
        showShareSheet(for: url, sourceView: sender, sourceRect: sender.bounds)
    }

    @objc private func goToButtonClicked() {
        guard let objectName = item.objectName else { return }
        let core = AppCore.shared
        let object = core.simulation.findObject(from: objectName)
        if object.isEmpty {
            showError(CelestiaString("Object not found", comment: ""))
            return
        }
        core.selectAndReceiveAsync(object, action: .goTo)
    }

    @objc private func progressButtonClicked() {
        let dm = ResourceManager.shared

        if dm.isInstalled(identifier: item.id) {
            // Already installed, offer option for uninstalling
            showOption(CelestiaString("Do you want to uninstall this add-on?", comment: "")) { [weak self] confirm in
                guard confirm, let self = self else { return }
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
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2, weight: .semibold)
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

        goToButton.isHidden = true
        goToButton.setTitle(CelestiaString("Go", comment: ""), for: .normal)

        buttonStack.axis = .vertical
        buttonStack.spacing = 8
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        goToButton.addTarget(self, action: #selector(goToButtonClicked), for: .touchUpInside)
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

        let isMacIdiom: Bool
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            isMacIdiom = true
        } else {
            isMacIdiom = false
        }

        switch currentState {
        case .none:
            progressButton.resetProgress()
            progressButton.setTitle(CelestiaString(isMacIdiom ? "Install" : "DOWNLOAD", comment: ""), for: .normal)
        case .downloading:
            progressButton.setTitle(CelestiaString(isMacIdiom ? "Cancel" : "DOWNLOADING", comment: ""), for: .normal)
        case .installed:
            progressButton.complete()
            progressButton.setTitle(CelestiaString(isMacIdiom ? "Uninstall" : "INSTALLED", comment: ""), for: .normal)
        }

        if currentState == .installed, let objectName = item.objectName, !AppCore.shared.simulation.findObject(from: objectName).isEmpty {
            goToButton.isHidden = false
        } else {
            goToButton.isHidden = true
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
