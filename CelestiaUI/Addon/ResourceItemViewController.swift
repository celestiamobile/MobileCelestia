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
import CoreSpotlight
import MobileCoreServices
import UIKit

public class ResourceItemViewController: UIViewController {
    enum ResourceItemState {
        case none
        case downloading
        case installed
    }

    private let itemID: String
    private var item: ResourceItem
    private let needsRefetchItem: Bool

    #if targetEnvironment(macCatalyst)
    private lazy var toolbarShareItem: NSSharingServicePickerToolbarItem = {
        let item = NSSharingServicePickerToolbarItem(itemIdentifier: .share)
        item.activityItemsConfiguration = UIActivityItemsConfiguration(objects: [URL.fromAddonForSharing(addonItemID: itemID, language: AppCore.language) as NSURL])
        return item
    }()
    #endif

    private lazy var progressView: UIProgressView = {
        if traitCollection.userInterfaceIdiom == .mac {
            return UIProgressView(progressViewStyle: .default)
        } else {
            return UIProgressView(progressViewStyle: .bar)
        }
    }()
    private lazy var statusButton = ActionButtonHelper.newButton()
    private lazy var statusButtonContainer: UIView = {
        if traitCollection.userInterfaceIdiom == .mac {
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

    private let resourceManager: ResourceManager

    private let actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?
    private let requestHandler: RequestHandler

    private lazy var itemInfoController: CommonWebViewController = {
        return CommonWebViewController(executor: executor, resourceManager: resourceManager, url: .fromAddon(addonItemID: itemID, language: AppCore.language), requestHandler: requestHandler, actionHandler: actionHandler, matchingQueryKeys: ["item"], contextDirectory: resourceManager.contextDirectory(forAddon: item))
    }()

    private var scrollViewTopToViewTopConstrant: NSLayoutConstraint?
    private var scrollViewTopToProgressViewBottomConstrant: NSLayoutConstraint?

    private var currentState: ResourceItemState = .none

    private var associatedUserActivity: NSUserActivity

    private let executor: AsyncProviderExecutor

    public init(executor: AsyncProviderExecutor, resourceManager: ResourceManager, item: ResourceItem, needsRefetchItem: Bool, requestHandler: RequestHandler, actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?) {
        self.executor = executor
        self.resourceManager = resourceManager
        self.itemID = item.id
        self.actionHandler = actionHandler
        self.requestHandler = requestHandler
        self.item = item
        self.needsRefetchItem = needsRefetchItem
        let userActivity = NSUserActivity(activityType: "space.celestia.celestia.addon-user-activity")
        userActivity.webpageURL = URL.fromAddonForSharing(addonItemID: itemID, language: AppCore.language)
        userActivity.title = item.name
        userActivity.isEligibleForHandoff = true
        userActivity.isEligibleForSearch = true
        userActivity.isEligibleForPrediction = true
        userActivity.isEligibleForPublicIndexing = true
        let contentAttributeSet = CSSearchableItemAttributeSet(contentType: .url)
        contentAttributeSet.contentCreationDate = item.publishTime
        contentAttributeSet.contentDescription = item.description
        userActivity.contentAttributeSet = contentAttributeSet
        userActivity.keywords = [item.name]
        self.associatedUserActivity = userActivity
        super.init(nibName: nil, bundle: nil)
        title = item.name
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()
        view.backgroundColor = .black
        setup()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareAddon(_:)))

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

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        associatedUserActivity.becomeCurrent()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        associatedUserActivity.resignCurrent()
    }

    private func refresh() {
        Task {
            do {
                let item = try await requestHandler.getMetadata(id: itemID, language: AppCore.language)
                self.item = item
                self.title = item.name
                self.associatedUserActivity.title = item.name
                self.associatedUserActivity.keywords = [item.name]
                self.associatedUserActivity.contentAttributeSet?.contentCreationDate = item.publishTime
                self.associatedUserActivity.contentAttributeSet?.contentDescription = item.description
                self.updateUI()
            } catch {}
        }
    }

    @objc private func goToButtonClicked() {
        if item.type == "script" {
            guard let mainScriptName = item.mainScriptName else { return }
            var isDir: ObjCBool = false
            guard let path = resourceManager.contextDirectory(forAddon: item)?.appendingPathComponent(mainScriptName).path,
                  FileManager.default.fileExists(atPath: path, isDirectory: &isDir),
                  !isDir.boolValue else {
                return
            }
            Task {
                await executor.run { appCore in
                    appCore.runScript(at: path)
                }
            }
            return
        }
        guard let objectName = item.objectName else { return }
        Task {
            let object = await executor.get { core in
                return core.simulation.findObject(from: objectName)
            }
            if object.isEmpty {
                showError(CelestiaString("Object not found", comment: ""))
                return
            }
            await executor.run { core in
                core.simulation.selection = object
                core.receive(.goTo)
            }
        }
    }

    @objc private func statusButtonClicked() {
        if resourceManager.isInstalled(item: item) {
            // Already installed, offer option for uninstalling
            showOption(CelestiaString("Do you want to uninstall this add-on?", comment: "")) { [weak self] confirm in
                guard confirm, let self = self else { return }
                do {
                    try self.resourceManager.uninstall(item: self.item)
                    self.currentState = .none
                } catch {
                    self.showError(CelestiaString("Unable to uninstall add-on.", comment: ""))
                }
                self.updateUI()
            }
            return
        }

        // Cancel if already downloading
        if resourceManager.isDownloading(identifier: itemID) {
            showOption(CelestiaString("Do you want to cancel this task?", comment: "Prompt to ask to cancel downloading an add-on")) { [weak self] confirm in
                guard confirm, let self = self, self.resourceManager.isDownloading(identifier: self.itemID) else { return }
                self.resourceManager.cancel(identifier: self.itemID)
                self.currentState = .none
                self.updateUI()
            }
            return
        }

        // Download
        resourceManager.download(item: item)
        currentState = .downloading
        updateUI()
    }

    @objc private func shareAddon(_ sender: UIBarButtonItem) {
        showShareSheet(for: URL.fromAddonForSharing(addonItemID: itemID, language: AppCore.language), source: .barButtonItem(barButtonItem: sender))
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

        if traitCollection.userInterfaceIdiom == .mac {
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
        goToButton.setTitle(CelestiaString("Go", comment: "Go to an object"), for: .normal)

        buttonStack.axis = .vertical
        buttonStack.spacing = GlobalConstants.pageLargeGapVertical
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: itemInfoController.view.bottomAnchor, constant: GlobalConstants.pageMediumGapVertical),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageMediumMarginVertical),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            buttonStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal)
        ])
        goToButton.addTarget(self, action: #selector(goToButtonClicked), for: .touchUpInside)
        statusButton.addTarget(self, action: #selector(statusButtonClicked), for: .touchUpInside)
    }

    private func updateUI() {
        if resourceManager.isInstalled(item: item) {
            currentState = .installed
        }
        if resourceManager.isDownloading(identifier: itemID) {
            currentState = .downloading
        }

        goToButton.setTitle(item.type == "script" ? CelestiaString("Run", comment: "Run a script") : CelestiaString("Go", comment: "Go to an object"), for: .normal)

        switch currentState {
        case .none:
            progressView.isHidden = true
            progressView.progress = 0
            statusButton.setTitle(CelestiaString("Install", comment: "Install an add-on"), for: .normal)
            if traitCollection.userInterfaceIdiom == .mac {
            } else {
                scrollViewTopToProgressViewBottomConstrant?.isActive = false
                scrollViewTopToViewTopConstrant?.isActive = true
            }
        case .downloading:
            progressView.isHidden = false
            statusButton.setTitle(CelestiaString("Cancel", comment: ""), for: .normal)
            if traitCollection.userInterfaceIdiom == .mac {
            } else {
                scrollViewTopToViewTopConstrant?.isActive = false
                scrollViewTopToProgressViewBottomConstrant?.isActive = true
            }
        case .installed:
            progressView.isHidden = true
            progressView.progress = 0
            statusButton.setTitle(CelestiaString("Uninstall", comment: "Uninstall an add-on"), for: .normal)
            if traitCollection.userInterfaceIdiom == .mac {
            } else {
                scrollViewTopToProgressViewBottomConstrant?.isActive = false
                scrollViewTopToViewTopConstrant?.isActive = true
            }
        }

        if item.type == "script" {
            if currentState == .installed, let mainScriptName = item.mainScriptName {
                var isDir: ObjCBool = false
                if let path = resourceManager.contextDirectory(forAddon: item)?.appendingPathComponent(mainScriptName).path,
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
            if currentState == .installed, let objectName = item.objectName {
                Task {
                    let exists = await executor.get { $0.simulation.findObject(from: objectName).isEmpty }
                    goToButton.isHidden = !exists
                }
            } else {
                goToButton.isHidden = true
            }
        }
    }
}

private extension ResourceItemViewController {
    @objc private func downloadProgress(_ notification: Notification) {
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == itemID else {
            return
        }

        guard let progress = notification.userInfo?[ResourceManager.downloadProgressKey] as? Double else {
            return
        }

        self.progressView.progress = Float(progress)
        self.updateUI()
    }

    @objc private func downloadSuccess(_ notification: Notification) {
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == itemID else {
            return
        }

        self.updateUI()
    }

    @objc private func resourceFetchError(_ notification: Notification) {
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == itemID else {
            return
        }
        guard let error = notification.userInfo?[ResourceManager.resourceErrorKey] as? ResourceManager.ResourceError else {
            return
        }
        self.currentState = .none
        self.updateUI()

        let message: String?
        switch error {
        case .cancelled:
            message = nil
        case .download:
            message = CelestiaString("Error downloading add-on", comment: "")
        case .zip:
            message = CelestiaString("Error unzipping add-on", comment: "")
        case .createDirectory:
            message = CelestiaString("Error creating directory for add-on", comment: "")
        case .openFile:
            message = CelestiaString("Error opening file for saving add-on", comment: "")
        case .writeFile:
            message = CelestiaString("Error writing data file for add-on", comment: "")
        }
        guard let message else { return }
        showError(CelestiaString("Failed to download or install this add-on.", comment: ""), detail: message)
    }

    @objc private func unzipSuccess(_ notification: Notification) {
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == itemID else {
            return
        }
        self.currentState = .installed
        self.updateUI()
    }
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    private static let prefix = Bundle(for: GoToInputViewController.self).bundleIdentifier!
    fileprivate static let share = NSToolbarItem.Identifier.init("\(prefix).share")
}

extension ResourceItemViewController: ToolbarAwareViewController {
    public func supportedToolbarItemIdentifiers(for toolbarContainerViewController: ToolbarContainerViewController) -> [NSToolbarItem.Identifier] {
        return [.share]
    }

    public func toolbarContainerViewController(_ toolbarContainerViewController: ToolbarContainerViewController, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        if itemIdentifier == .share {
            return toolbarShareItem
        }
        return nil
    }
}
#endif
