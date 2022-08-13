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

import CelestiaCore
import MWRequest
import UIKit

class ResourceItemViewController: UIViewController {
    enum ResourceItemState {
        case none
        case downloading
        case installed
    }

    private var item: ResourceItem
    private let needsRefetchItem: Bool

    private lazy var progressView: UIProgressView = {
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            return UIProgressView(progressViewStyle: .default)
        } else {
            return UIProgressView(progressViewStyle: .bar)
        }
    }()
    private lazy var statusButton = ActionButtonHelper.newButton()
    private lazy var statusButtonContainer: UIView = {
        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            let stackView = UIStackView(arrangedSubviews: [progressView, statusButton])
            stackView.axis = .horizontal
            stackView.spacing = GlobalConstants.pageMediumGapHorizontal
            stackView.alignment = .center
            return stackView
        } else {
            return statusButton
        }
    }()
    private lazy var goToButton = ActionButtonHelper.newButton()
    private lazy var buttonStack = UIStackView(arrangedSubviews: [goToButton, statusButtonContainer])

    private lazy var itemInfoController: CommonWebViewController = {
        return CommonWebViewController(url: .fromAddon(addonItemID: item.id, language: AppCore.language), matchingQueryKeys: ["item"], contextDirectory: ResourceManager.shared.contextDirectory(forAddonWithIdentifier: item.id))
    }()

    private var scrollViewTopToViewTopConstrant: NSLayoutConstraint?
    private var scrollViewTopToProgressViewBottomConstrant: NSLayoutConstraint?

    private var currentState: ResourceItemState = .none

    init(item: ResourceItem, needsRefetchItem: Bool) {
        self.item = item
        self.needsRefetchItem = needsRefetchItem
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .black
        setup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()

        NotificationCenter.default.addObserver(self, selector: #selector(downloadProgress(_:)), name: ResourceManager.downloadProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resourceFetchError(_:)), name: ResourceManager.resourceError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadSuccess(_:)), name: ResourceManager.downloadSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unzipSuccess(_:)), name: ResourceManager.unzipSuccess, object: nil)

        // Fetch the latest item, this is needed as user might come
        // here from Installed where the URL might be incorrect
        if needsRefetchItem {
            refresh()
        }
    }

    private func refresh() {
        let requestURL = apiPrefix + "/resource/item"
        _ = RequestHandler.get(url: requestURL, parameters: ["lang": AppCore.language, "item": item.id], success: { [weak self] (item: ResourceItem) in
            guard let self = self else { return }
            self.item = item
            self.updateUI()
        }, decoder: ResourceItem.networkResponseDecoder)
    }

    @objc private func goToButtonClicked() {
        if item.type == "script" {
            guard let mainScriptName = item.mainScriptName else { return }
            var isDir: ObjCBool = false
            guard let path = ResourceManager.shared.contextDirectory(forAddonWithIdentifier: item.id)?.appendingPathComponent(mainScriptName).path,
                  FileManager.default.fileExists(atPath: path, isDirectory: &isDir),
                  !isDir.boolValue else {
                return
            }
            NotificationCenter.default.post(name: newURLOpenedNotificationName, object: nil, userInfo: [
                newURLOpenedNotificationURLKey: UniformedURL(url: URL(fileURLWithPath: path), securityScoped: false),
            ])
            return
        }
        guard let objectName = item.objectName else { return }
        let core = AppCore.shared
        let object = core.simulation.findObject(from: objectName)
        if object.isEmpty {
            showError(CelestiaString("Object not found", comment: ""))
            return
        }
        core.selectAndReceiveAsync(object, action: .goTo)
    }

    @objc private func statusButtonClicked() {
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
        addChild(itemInfoController)

        itemInfoController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(itemInfoController.view)

        NSLayoutConstraint.activate([
            itemInfoController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            itemInfoController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            NSLayoutConstraint.activate([
                itemInfoController.view.topAnchor.constraint(equalTo: view.topAnchor),
            ])
        } else {
            view.addSubview(progressView)
            progressView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])

            scrollViewTopToViewTopConstrant = itemInfoController.view.topAnchor.constraint(equalTo: view.topAnchor)
            scrollViewTopToProgressViewBottomConstrant = itemInfoController.view.topAnchor.constraint(equalTo: progressView.bottomAnchor)

            scrollViewTopToProgressViewBottomConstrant?.isActive = false
            scrollViewTopToViewTopConstrant?.isActive = true
        }

        itemInfoController.didMove(toParent: self)

        progressView.isHidden = true

        goToButton.isHidden = true
        goToButton.setTitle(CelestiaString("Go", comment: ""), for: .normal)

        buttonStack.axis = .vertical
        buttonStack.spacing = GlobalConstants.pageLargeGapVertical
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: itemInfoController.view.bottomAnchor, constant: GlobalConstants.pageMediumGapVertical),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageMarginVertical),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: GlobalConstants.pageMarginHorizontal),
            buttonStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -GlobalConstants.pageMarginHorizontal)
        ])
        goToButton.addTarget(self, action: #selector(goToButtonClicked), for: .touchUpInside)
        statusButton.addTarget(self, action: #selector(statusButtonClicked), for: .touchUpInside)
    }

    private func updateUI() {
        let dm = ResourceManager.shared
        if dm.isInstalled(identifier: item.id) {
            currentState = .installed
        }
        if dm.isDownloading(identifier: item.id) {
            currentState = .downloading
        }

        goToButton.setTitle(CelestiaString(item.type == "script" ? "Run" : "Go", comment: ""), for: .normal)

        switch currentState {
        case .none:
            progressView.isHidden = true
            progressView.progress = 0
            statusButton.setTitle(CelestiaString("Install", comment: ""), for: .normal)
            if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            } else {
                scrollViewTopToProgressViewBottomConstrant?.isActive = false
                scrollViewTopToViewTopConstrant?.isActive = true
            }
        case .downloading:
            progressView.isHidden = false
            statusButton.setTitle(CelestiaString("Cancel", comment: ""), for: .normal)
            if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            } else {
                scrollViewTopToViewTopConstrant?.isActive = false
                scrollViewTopToProgressViewBottomConstrant?.isActive = true
            }
        case .installed:
            progressView.isHidden = true
            progressView.progress = 0
            statusButton.setTitle(CelestiaString("Uninstall", comment: ""), for: .normal)
            if #available(iOS 14.0, *), traitCollection.userInterfaceIdiom == .mac {
            } else {
                scrollViewTopToProgressViewBottomConstrant?.isActive = false
                scrollViewTopToViewTopConstrant?.isActive = true
            }
        }

        if item.type == "script" {
            if currentState == .installed, let mainScriptName = item.mainScriptName {
                var isDir: ObjCBool = false
                if let path = dm.contextDirectory(forAddonWithIdentifier: item.id)?.appendingPathComponent(mainScriptName).path,
                   FileManager.default.fileExists(atPath: path, isDirectory: &isDir),
                   !isDir.boolValue {
                    goToButton.isHidden = false
                } else {
                    goToButton.isHidden = true
                }
            } else {
                goToButton.isHidden = true
            }
        } else {
            if currentState == .installed, let objectName = item.objectName, !AppCore.shared.simulation.findObject(from: objectName).isEmpty {
                goToButton.isHidden = false
            } else {
                goToButton.isHidden = true
            }
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
            self?.progressView.progress = Float(progress)
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
