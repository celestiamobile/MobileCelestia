// ResourceItemViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CoreSpotlight
import MobileCoreServices
import SwiftUI
import UIKit

enum ResourceItemAction {
    case go(selection: Selection)
    case run(scriptPath: String)
}

enum ResourceItemState {
    case none
    case downloading
    case installed
}

@available(iOS 16, visionOS 1, *)
private struct WebInfoView: UIViewControllerRepresentable {
    let executor: AsyncProviderExecutor
    let resourceManager: ResourceManager
    let url: URL
    let requestHandler: RequestHandler
    let actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?
    let matchingQueryKeys: [String]
    let contextDirectory: URL?
    let filterURL: Bool
    @Binding var bottomSafeAreaHeight: CGFloat

    func updateUIViewController(_ uiViewController: CommonWebViewController, context: Context) {
        uiViewController.additionalSafeAreaInsets.bottom = bottomSafeAreaHeight
    }
    
    func makeUIViewController(context: Context) -> CommonWebViewController {
        let vc = CommonWebViewController(executor: executor, resourceManager: resourceManager, url: url, requestHandler: requestHandler, actionHandler: actionHandler, matchingQueryKeys: matchingQueryKeys, contextDirectory: contextDirectory)
        return vc
    }
}

private class ResourceItemViewModel: ObservableObject {
    @Published var item: ResourceItem
    @Published var state: ResourceItemState = .none
    @Published var action: ResourceItemAction?
    @Published var progress: Float = 0
    let executor: AsyncProviderExecutor
    let resourceManager: ResourceManager
    let requestHandler: RequestHandler
    let actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?

    init(
        item: ResourceItem,
        executor: AsyncProviderExecutor,
        resourceManager: ResourceManager,
        requestHandler: RequestHandler,
        actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?
    ) {
        self.item = item
        self.executor = executor
        self.resourceManager = resourceManager
        self.requestHandler = requestHandler
        self.actionHandler = actionHandler
    }
}

@available(iOS 16, visionOS 1, *)
private struct ResourceItemView: View {
    @ObservedObject var viewModel: ResourceItemViewModel
    @State var bottomSafeAreaHeight: CGFloat = 0
    let statusButtonHandler: () -> Void
    let actionButtonHandler: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            WebInfoView(
                executor: viewModel.executor,
                resourceManager: viewModel.resourceManager,
                url: .fromAddon(addonItemID: viewModel.item.id, language: AppCore.language),
                requestHandler: viewModel.requestHandler,
                actionHandler: viewModel.actionHandler,
                matchingQueryKeys: ["item"],
                contextDirectory: viewModel.resourceManager.contextDirectory(forAddon: viewModel.item),
                filterURL: true,
                bottomSafeAreaHeight: $bottomSafeAreaHeight
            )
            .ignoresSafeArea()
            #if !os(iOS) || !targetEnvironment(macCatalyst)
            if viewModel.state == .downloading {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
            }
            #endif
        }
        .safeArea {
            VStack(spacing: GlobalConstants.pageLargeGapVertical) {
                if viewModel.state == .installed, let action = viewModel.action {
                    Button {
                        actionButtonHandler()
                    } label: {
                        switch action {
                        case .go:
                            Text(verbatim: CelestiaString("Go", comment: "Go to an object"))
                                .frame(maxWidth: .infinity)
                        case .run:
                            Text(verbatim: CelestiaString("Run", comment: "Run a script"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .prominentGlassButtonStyle()
                    #if targetEnvironment(macCatalyst)
                    .controlSize(.large)
                    #endif
                }

                HStack(spacing: GlobalConstants.pageMediumGapHorizontal) {
                    #if os(iOS) && targetEnvironment(macCatalyst)
                    if viewModel.state == .downloading {
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(.linear)
                    }
                    #endif
                    
                    Button {
                        statusButtonHandler()
                    } label: {
                        switch viewModel.state {
                        case .none:
                            Text(verbatim: CelestiaString("Install", comment: "Install an add-on"))
                                .frame(maxWidth: .infinity)
                        case .downloading:
                            Text(verbatim: CelestiaString("Cancel", comment: ""))
                            #if !os(iOS) || !targetEnvironment(macCatalyst)
                                .frame(maxWidth: .infinity)
                            #endif
                        case .installed:
                            Text(verbatim: CelestiaString("Uninstall", comment: "Uninstall an add-on"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .glassButtonStyle()
                    #if targetEnvironment(macCatalyst)
                    .controlSize(.large)
                    #endif
                }
            }
            .padding(EdgeInsets(top: GlobalConstants.pageMediumMarginVertical, leading: GlobalConstants.pageMediumMarginHorizontal, bottom: GlobalConstants.pageMediumMarginVertical, trailing: GlobalConstants.pageMediumMarginHorizontal))
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newValue in
                #if os(visionOS)
                if #available(visionOS 26, *) {
                    bottomSafeAreaHeight = newValue.height
                }
                #else
                bottomSafeAreaHeight = newValue.height
                #endif
            }
        }
    }
}

public class ResourceItemViewController: UIViewController {
    private let needsRefetchItem: Bool

    #if targetEnvironment(macCatalyst)
    private lazy var toolbarShareItem: NSSharingServicePickerToolbarItem = {
        let item = NSSharingServicePickerToolbarItem(itemIdentifier: .share)
        item.activityItemsConfiguration = UIActivityItemsConfiguration(objects: [URL.fromAddonForSharing(addonItemID: viewModel.item.id, language: AppCore.language) as NSURL])
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
    private lazy var statusButton = ActionButtonHelper.newButton(traitCollection: traitCollection)
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
    private lazy var goToButton = ActionButtonHelper.newButton(prominent: true, traitCollection: traitCollection)
    private lazy var buttonStack = UIStackView(arrangedSubviews: [goToButton, statusButtonContainer])

    private var scrollViewTopToViewTopConstrant: NSLayoutConstraint?
    private var scrollViewTopToProgressViewBottomConstrant: NSLayoutConstraint?

    private var viewIsVisible = false
    private var associatedUserActivity: NSUserActivity

    private let viewModel: ResourceItemViewModel

    public init(executor: AsyncProviderExecutor, resourceManager: ResourceManager, item: ResourceItem, needsRefetchItem: Bool, requestHandler: RequestHandler, actionHandler: ((CommonWebViewController.WebAction, UIViewController) -> Void)?) {
        viewModel = ResourceItemViewModel(item: item, executor: executor, resourceManager: resourceManager, requestHandler: requestHandler, actionHandler: actionHandler)
        self.needsRefetchItem = needsRefetchItem
        let userActivity = NSUserActivity(activityType: "space.celestia.celestia.addon-user-activity")
        userActivity.webpageURL = URL.fromAddonForSharing(addonItemID: item.id, language: AppCore.language)
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
        windowTitle = item.name
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 16, visionOS 1, *) {
            let vc = UIHostingController(rootView: ResourceItemView(viewModel: viewModel, statusButtonHandler: { [weak self] in
                guard let self else { return }
                self.statusButtonClicked()
            }, actionButtonHandler: { [weak self] in
                guard let self else { return }
                self.goToButtonClicked()
            }))
            install(vc)
        } else {
            setup()
        }

        updateUI()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareAddon(_:)))

        NotificationCenter.default.addObserver(self, selector: #selector(downloadProgress(_:)), name: ResourceManager.downloadProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resourceFetchError(_:)), name: ResourceManager.resourceError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadSuccess(_:)), name: ResourceManager.downloadSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unzipSuccess(_:)), name: ResourceManager.unzipSuccess, object: nil)
        #if targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(self, selector: #selector(handleWindowWillBecomeKey(_:)), name: Notification.Name("_UIWindowWillBecomeApplicationKeyNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleWindowDidResignKey(_:)), name: Notification.Name("_UIWindowDidResignApplicationKeyNotification"), object: nil)
        #endif

        // Fetch the latest item, this is needed as user might come
        // here from Installed where the URL might be incorrect
        if needsRefetchItem {
            refresh()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewIsVisible = true
        #if targetEnvironment(macCatalyst)
        if view.window?.isKeyWindow == true {
            associatedUserActivity.becomeCurrent()
        }
        #else
        associatedUserActivity.becomeCurrent()
        #endif
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewIsVisible = false
        associatedUserActivity.resignCurrent()
    }

    private func refresh() {
        Task {
            do {
                let item = try await viewModel.requestHandler.getMetadata(id: viewModel.item.id, language: AppCore.language)
                self.viewModel.item = item
                self.title = item.name
                self.windowTitle = self.title
                self.associatedUserActivity.title = item.name
                self.associatedUserActivity.keywords = [item.name]
                self.associatedUserActivity.contentAttributeSet?.contentCreationDate = item.publishTime
                self.associatedUserActivity.contentAttributeSet?.contentDescription = item.description
                self.updateUI()
            } catch {}
        }
    }

    @objc private func goToButtonClicked() {
        guard let action = viewModel.action else { return }

        switch action {
        case let .go(selection):
            Task {
                await viewModel.executor.run { core in
                    core.simulation.selection = selection
                    core.receive(.goTo)
                }
            }
        case let .run(scriptPath):
            Task {
                await viewModel.executor.run { appCore in
                    appCore.runScript(at: scriptPath)
                }
            }
        }

    }

    @objc private func statusButtonClicked() {
        if viewModel.resourceManager.isInstalled(item: viewModel.item) {
            // Already installed, offer option for uninstalling
            showOption(CelestiaString("Do you want to uninstall this add-on?", comment: "")) { [weak self] confirm in
                guard confirm, let self = self else { return }
                do {
                    try self.viewModel.resourceManager.uninstall(item: self.viewModel.item)
                    self.viewModel.state = .none
                } catch {
                    self.showError(CelestiaString("Unable to uninstall add-on.", comment: ""))
                }
                self.updateUI()
            }
            return
        }

        // Cancel if already downloading
        if viewModel.resourceManager.isDownloading(identifier: viewModel.item.id) {
            showOption(CelestiaString("Do you want to cancel this task?", comment: "Prompt to ask to cancel downloading an add-on")) { [weak self] confirm in
                guard confirm, let self = self, self.viewModel.resourceManager.isDownloading(identifier: self.viewModel.item.id) else { return }
                self.viewModel.resourceManager.cancel(identifier: self.viewModel.item.id)
                self.viewModel.state = .none
                self.updateUI()
            }
            return
        }

        // Download
        viewModel.resourceManager.download(item: viewModel.item)
        viewModel.state = .downloading
        updateUI()
    }

    @objc private func shareAddon(_ sender: UIBarButtonItem) {
        showShareSheet(for: URL.fromAddonForSharing(addonItemID: viewModel.item.id, language: AppCore.language), source: .barButtonItem(barButtonItem: sender))
    }
}

private extension ResourceItemViewController {
    func setup() {
        let itemInfoController = CommonWebViewController(executor: viewModel.executor, resourceManager: viewModel.resourceManager, url: .fromAddon(addonItemID: viewModel.item.id, language: AppCore.language), requestHandler: viewModel.requestHandler, actionHandler: viewModel.actionHandler, matchingQueryKeys: ["item"], contextDirectory: viewModel.resourceManager.contextDirectory(forAddon: viewModel.item))
        addChild(itemInfoController)

        itemInfoController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(itemInfoController.view)

        NSLayoutConstraint.activate([
            itemInfoController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            itemInfoController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageMediumMarginVertical),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: GlobalConstants.pageMediumMarginHorizontal),
            buttonStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -GlobalConstants.pageMediumMarginHorizontal),
            buttonStack.topAnchor.constraint(equalTo: itemInfoController.view.bottomAnchor, constant: GlobalConstants.pageMediumGapVertical),
        ])
        goToButton.addTarget(self, action: #selector(goToButtonClicked), for: .touchUpInside)
        statusButton.addTarget(self, action: #selector(statusButtonClicked), for: .touchUpInside)
    }

    private func updateUI() {
        if viewModel.resourceManager.isInstalled(item: viewModel.item) {
            viewModel.state = .installed
        }
        if viewModel.resourceManager.isDownloading(identifier: viewModel.item.id) {
            viewModel.state = .downloading
        }

        goToButton.setTitle(viewModel.item.type == "script" ? CelestiaString("Run", comment: "Run a script") : CelestiaString("Go", comment: "Go to an object"), for: .normal)

        switch viewModel.state {
        case .none:
            progressView.isHidden = true
            progressView.progress = 0
            viewModel.progress = 0
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
            viewModel.progress = 0
            statusButton.setTitle(CelestiaString("Uninstall", comment: "Uninstall an add-on"), for: .normal)
            if traitCollection.userInterfaceIdiom == .mac {
            } else {
                scrollViewTopToProgressViewBottomConstrant?.isActive = false
                scrollViewTopToViewTopConstrant?.isActive = true
            }
        }

        if viewModel.item.type == "script" {
            if viewModel.state == .installed, let mainScriptName = viewModel.item.mainScriptName {
                var isDir: ObjCBool = false
                if let path = viewModel.resourceManager.contextDirectory(forAddon: viewModel.item)?.appendingPathComponent(mainScriptName).path,
                   FileManager.default.fileExists(atPath: path, isDirectory: &isDir),
                   !isDir.boolValue {
                    viewModel.action = nil
                    goToButton.isHidden = false
                } else {
                    viewModel.action = nil
                    goToButton.isHidden = true
                }
            } else {
                viewModel.action = nil
                goToButton.isHidden = true
            }
        } else {
            if viewModel.state == .installed, let objectName = viewModel.item.objectName {
                Task {
                    let selection = await viewModel.executor.get { $0.simulation.findObject(from: objectName) }
                    viewModel.action = selection.isEmpty ? nil : .go(selection: selection)
                    goToButton.isHidden = selection.isEmpty
                }
            } else {
                viewModel.action = nil
                goToButton.isHidden = true
            }
        }
    }
}

private extension ResourceItemViewController {
    @objc private func downloadProgress(_ notification: Notification) {
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == viewModel.item.id else {
            return
        }

        guard let progress = notification.userInfo?[ResourceManager.downloadProgressKey] as? Double else {
            return
        }

        self.viewModel.progress = Float(progress)
        self.progressView.progress = Float(progress)
        self.updateUI()
    }

    @objc private func downloadSuccess(_ notification: Notification) {
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == viewModel.item.id else {
            return
        }

        self.updateUI()
    }

    @objc private func resourceFetchError(_ notification: Notification) {
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == viewModel.item.id else {
            return
        }
        guard let error = notification.userInfo?[ResourceManager.resourceErrorKey] as? ResourceManager.ResourceError else {
            return
        }
        self.viewModel.state = .none
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
        guard let identifier = notification.userInfo?[ResourceManager.downloadIdentifierKey] as? String, identifier == viewModel.item.id else {
            return
        }
        self.viewModel.state = .installed
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

private extension ResourceItemViewController {
    @objc func handleWindowWillBecomeKey(_ notification: Notification) {
        guard let object = notification.object as? NSObject, object === view.window else { return }

        if viewIsVisible {
            associatedUserActivity.becomeCurrent()
        }
    }

    @objc func handleWindowDidResignKey(_ notification: Notification) {
        guard let object = notification.object as? NSObject, object === view.window else { return }

        associatedUserActivity.resignCurrent()
    }
}
#endif
