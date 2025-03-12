// CelestiaDisplayController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import AsyncGLANGLE
import CelestiaCore
import CelestiaFoundation
import CelestiaUI
import UIKit

protocol CelestiaDisplayControllerDelegate: AnyObject {
    func celestiaDisplayController(_ celestiaDisplayController: CelestiaDisplayController, loadingStatusUpdated status: String)
    func celestiaDisplayControllerLoadingFailedShouldRetry(_ celestiaDisplayController: CelestiaDisplayController) -> Bool
    func celestiaDisplayControllerLoadingFailed(_ celestiaDisplayController: CelestiaDisplayController)
    func celestiaDisplayControllerLoadingSucceeded(_ celestiaDisplayController: CelestiaDisplayController)
}

class CelestiaDisplayController: AsyncGLViewController {
    private let core: AppCore
    private let executor: CelestiaExecutor
    private let userDefaults: UserDefaults
    private let subscriptionManager: SubscriptionManager
    private let stateManager = StateManager.shared

    // MARK: rendering
    private nonisolated(unsafe) var currentSize: CGSize = .zero

    private nonisolated(unsafe) var isLoaded = false
    private var isInBackground = false

    private var isReady: Bool {
        return isLoaded && !isInBackground
    }

    private nonisolated(unsafe) var dataDirectoryURL: UniformedURL!
    private nonisolated(unsafe) var configFileURL: UniformedURL!

    private var currentViewScale: CGFloat = 1

    nonisolated(unsafe) weak var delegate: CelestiaDisplayControllerDelegate?

    #if targetEnvironment(macCatalyst)
    private static nonisolated let windowWillStartLiveResizeNotification = Notification.Name("NSWindowWillStartLiveResizeNotification")
    private static nonisolated let windowDidEndLiveResizeNotification = Notification.Name("NSWindowDidEndLiveResizeNotification")
    #endif

    private nonisolated(unsafe) var isRTL = false

    #if targetEnvironment(macCatalyst)
    private nonisolated(unsafe) var sensitivity: Double = 4.0
    #else
    private nonisolated(unsafe) var sensitivity: Double = 10.0
    #endif

    init(msaaEnabled: Bool, screen: UIScreen, initialFrameRate frameRate: Int, executor: CelestiaExecutor, subscriptionManager: SubscriptionManager, core: AppCore, userDefaults: UserDefaults) {
#if targetEnvironment(macCatalyst)
        let api = AsyncGLAPI.openGLES2
#else
        let api = AsyncGLAPI.openGLES2
#endif
        self.subscriptionManager = subscriptionManager
        self.core = core
        self.executor = executor
        self.userDefaults = userDefaults
        super.init(msaaEnabled: msaaEnabled, initialFrameRate: frameRate, api: api, executor: executor)

        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitDisplayScale.self, UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
                self.displayScaleOrContentSizeCategoryChanged()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isRTL = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft

        #if targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillStartLiveResizing(_:)), name: Self.windowWillStartLiveResizeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidEndLiveResizing(_:)), name: Self.windowDidEndLiveResizeNotification, object: nil)
        #else
        view.contentMode = .center
        #endif
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        guard isLoaded else { return }

        let insets = view.safeAreaInsets.scale(by: view.contentScaleFactor)
        executor.runAsynchronously { core in
            core.setSafeAreaInsets(insets)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 17, *) {
        } else {
            if traitCollection.displayScale != previousTraitCollection?.displayScale || traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
                displayScaleOrContentSizeCategoryChanged()
            }
        }
    }

    #if targetEnvironment(macCatalyst)
    @objc private func windowWillStartLiveResizing(_ notification: Notification) {
        guard let window = view.window else { return }

        if notification.object as? NSObject == window.nsWindow {
            isPaused = true
        }
    }

    @objc private func windowDidEndLiveResizing(_ notification: Notification) {
        guard let window = view.window else { return }

        if notification.object as? NSObject == window.nsWindow {
            isPaused = false
        }
    }
    #else
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        isPaused = true
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.isPaused = false
        }
    }
    #endif
}

extension CelestiaDisplayController {
    override func prepareGL(_ size: CGSize, samples: Int) -> Bool {
        _ = AppCore.initGL()

        var success = false
        var shouldRetry = true

        while !success && shouldRetry {
            self.dataDirectoryURL = userDefaults.currentDataDirectory()
            self.configFileURL = userDefaults.currentConfigFile()

            FileManager.default.changeCurrentDirectoryPath(self.dataDirectoryURL.url.path)
            AppCore.setLocaleDirectory(self.dataDirectoryURL.url.appendingPathComponent("locale").path)

            guard self.core.startSimulation(configFileName: self.configFileURL.url.path, extraDirectories: [UserDefaults.extraDirectory].compactMap{$0?.path}, progress: { (st) in
                delegate?.celestiaDisplayController(self, loadingStatusUpdated: st)
            }) else {
                shouldRetry = delegate?.celestiaDisplayControllerLoadingFailedShouldRetry(self) ?? false
                continue
            }

            guard self.core.startRenderer() else {
                print("Failed to start renderer.")
                shouldRetry = delegate?.celestiaDisplayControllerLoadingFailedShouldRetry(self) ?? false
                continue
            }

            self.core.load(userDefaults, withAppDefaultsAtPath: Bundle.app.path(forResource: "defaults", ofType: "plist"))
            success = true
        }

        if !success {
            delegate?.celestiaDisplayControllerLoadingFailed(self)

            Task { @MainActor in
                stateManager.markAsInitialized(.failedToLoad)
            }
            return false
        }

        core.layoutDirection = isRTL ? .RTL : .LTR
        let (viewSpec, fonts, hasPendingRequests) = DispatchQueue.main.sync {
            return (getViewSpec(), getFonts(), stateManager.hasPendingRequests)
        }
        if let sensitivityValue: Double = userDefaults[UserDefaultsKey.pickSensitivity] {
            self.sensitivity = sensitivityValue
        }
        let sensitivity = self.sensitivity
        updateContentScale(viewSpec: viewSpec, sensitivity: sensitivity, core: core)

        core.setHudFont(fonts.normal.path, collectionIndex: fonts.normal.ttcIndex, fontSize: 9)
        core.setHudTitleFont(fonts.bold.path, collectionIndex: fonts.bold.ttcIndex, fontSize: 15)
        core.setRendererFont(fonts.normal.path, collectionIndex: fonts.normal.ttcIndex, fontSize: 9, fontStyle: .normal)
        core.setRendererFont(fonts.bold.path, collectionIndex: fonts.bold.ttcIndex, fontSize: 15, fontStyle: .large)

        core.tick()
        core.start()

        if hasPendingRequests {
            core.cancelScript()
        }

        isLoaded = true
        delegate?.celestiaDisplayControllerLoadingSucceeded(self)

        Task { @MainActor in
            stateManager.markAsInitialized(.loaded(core))
        }
        return true
    }

    override func drawGL(_ size: CGSize) {
        if size != currentSize {
            currentSize = size
            core.resize(to: currentSize)
        }

        core.draw()
        core.tick()
    }
}

private extension AppCore {
    func setSafeAreaInsets(_ safeAreaInsets: UIEdgeInsets) {
        setSafeAreaInsets(left: safeAreaInsets.left, top: safeAreaInsets.top, right: safeAreaInsets.right, bottom: safeAreaInsets.bottom)
    }
}

extension CelestiaDisplayController {
    private struct ViewSpec {
        let viewSafeAreaInsets: UIEdgeInsets
        let viewScale: CGFloat
        let applicationScalingFactor: CGFloat
        let textScaleFactor: CGFloat
    }

    private func displayScaleOrContentSizeCategoryChanged() {
        guard isLoaded else { return }

        let viewSpec = getViewSpec()
        let core = self.core
        let executor = self.executor
        let sensitivity = self.sensitivity
        executor.runAsynchronously { _ in
            self.updateContentScale(viewSpec: viewSpec, sensitivity: sensitivity, core: core)
        }
    }

    private func getViewSpec() -> ViewSpec {
        let viewScale = userDefaults[.fullDPI] != false ? self.traitCollection.displayScale : 1
        self.view.contentScaleFactor = viewScale
        var applicationScalingFactor: CGFloat = 1.0

        #if targetEnvironment(macCatalyst)
        applicationScalingFactor = MacBridge.catalystScaleFactor
        #else
        applicationScalingFactor = ProcessInfo.processInfo.isiOSAppOnMac ? 0.77 : 1
        #endif

        return ViewSpec(
            viewSafeAreaInsets: view.safeAreaInsets,
            viewScale: viewScale,
            applicationScalingFactor: applicationScalingFactor,
            textScaleFactor: UIFontMetrics.default.scaledValue(for: 10000, compatibleWith: traitCollection) / 10000
        )
    }

    private struct Fonts {
        let normal: CustomFont
        let bold: CustomFont
    }

    private func getFonts() -> Fonts {
        let hasCelestiaPlus = subscriptionManager.transactionInfo() != nil
        var customNormalFont: CustomFont?
        var customBoldFont: CustomFont?
        if hasCelestiaPlus {
            if let customNormalFontPath: String = userDefaults[UserDefaultsKey.normalFontPath] {
                let fontIndex: Int = userDefaults[UserDefaultsKey.normalFontIndex] ?? 0
                customNormalFont = CustomFont(path: customNormalFontPath, ttcIndex: fontIndex)
            }
            if let customBoldFontPath: String = userDefaults[UserDefaultsKey.boldFontPath] {
                let fontIndex: Int = userDefaults[UserDefaultsKey.boldFontIndex] ?? 0
                customBoldFont = CustomFont(path: customBoldFontPath, ttcIndex: fontIndex)
            }
        }

        var (normalFont, boldFont) = getInstalledFontFor(locale: AppCore.language)
        if let customNormalFont = customNormalFont {
            normalFont = customNormalFont
        }
        if let customBoldFont = customBoldFont {
            boldFont = customBoldFont
        }
        return Fonts(normal: normalFont, bold: boldFont)
    }

    nonisolated private func updateContentScale(viewSpec: ViewSpec, sensitivity: CGFloat, core: AppCore) {
        core.screenDPI = Int(96.0 * viewSpec.viewScale / viewSpec.applicationScalingFactor)
        core.setSafeAreaInsets(viewSpec.viewSafeAreaInsets.scale(by: viewSpec.viewScale))
        core.setPickTolerance(sensitivity * viewSpec.viewScale / viewSpec.applicationScalingFactor)
        core.textScaleFactor = viewSpec.textScaleFactor
    }
}

extension CelestiaDisplayController {
    var targetGeometry: RenderingTargetGeometry {
        return RenderingTargetGeometry(size: view.frame.size, scale: view.contentScaleFactor)
    }
}

typealias FallbackFont = (filePath: String, collectionIndex: Int)

private func getInstalledFontFor(locale: String) -> (font: CustomFont, boldFont: CustomFont) {
    let fontDir = Bundle.app.path(forResource: "Fonts", ofType: nil)!
    let fontFallback = [
        "ja": (
            font: CustomFont(path: "\(fontDir)/NotoSansCJK-Regular.ttc", ttcIndex: 0),
            boldFont: CustomFont(path: "\(fontDir)/NotoSansCJK-Bold.ttc", ttcIndex: 0)
        ),
        "ka": (
            font: CustomFont(path: "\(fontDir)/NotoSansGeorgian-Regular.ttf", ttcIndex: 0),
            boldFont: CustomFont(path: "\(fontDir)/NotoSansGeorgian-Bold.ttf", ttcIndex: 0)
        ),
        "ko": (
            font: CustomFont(path: "\(fontDir)/NotoSansCJK-Regular.ttc", ttcIndex: 1),
            boldFont: CustomFont(path: "\(fontDir)/NotoSansCJK-Bold.ttc", ttcIndex: 1)
        ),
        "zh_CN": (
            font: CustomFont(path: "\(fontDir)/NotoSansCJK-Regular.ttc", ttcIndex: 2),
            boldFont: CustomFont(path: "\(fontDir)/NotoSansCJK-Bold.ttc", ttcIndex: 2)
        ),
        "zh_TW": (
            font: CustomFont(path: "\(fontDir)/NotoSansCJK-Regular.ttc", ttcIndex: 3),
            boldFont: CustomFont(path: "\(fontDir)/NotoSansCJK-Bold.ttc", ttcIndex: 3)
        ),
        "ar": (
            font: CustomFont(path: "\(fontDir)/NotoSansArabic-Regular.ttf", ttcIndex: 0),
            boldFont: CustomFont(path: "\(fontDir)/NotoSansArabic-Bold.ttf", ttcIndex: 0)
        )
    ]
    let def = (
        font: CustomFont(path: "\(fontDir)/NotoSans-Regular.ttf", ttcIndex: 0),
        boldFont: CustomFont(path: "\(fontDir)/NotoSans-Bold.ttf", ttcIndex: 0)
    )
    return fontFallback[locale] ?? def
}

extension CelestiaDisplayController {
    func screenshot() -> Any? {
        return self.view.snapshotView(afterScreenUpdates: false)?.layer.contents
    }
}

private extension UIEdgeInsets {
    func scale(by factor: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: top * factor, left: left * factor, bottom: bottom * factor, right: right * factor)
    }
}
