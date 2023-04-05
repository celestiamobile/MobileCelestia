//
// CelestiaDisplayController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit
import CelestiaCore

import AsyncGL

protocol CelestiaDisplayControllerDelegate: AnyObject {
    func celestiaDisplayController(_ celestiaDisplayController: CelestiaDisplayController, loadingStatusUpdated status: String)
    func celestiaDisplayControllerLoadingFailedShouldRetry(_ celestiaDisplayController: CelestiaDisplayController) -> Bool
    func celestiaDisplayControllerLoadingFailed(_ celestiaDisplayController: CelestiaDisplayController)
    func celestiaDisplayControllerLoadingSucceeded(_ celestiaDisplayController: CelestiaDisplayController)
}

class CelestiaDisplayController: AsyncGLViewController {
    @Injected(\.appCore) private var core
    @Injected(\.executor) private var executor
    @Injected(\.userDefaults) private var userDefaults

    // MARK: rendering
    private var currentSize: CGSize = .zero

    private var isLoaded = false
    private var isInBackground = false

    private var isReady: Bool {
        return isLoaded && !isInBackground
    }

    private var dataDirectoryURL: UniformedURL!
    private var configFileURL: UniformedURL!

    private var currentViewScale: CGFloat = 1

    weak var delegate: CelestiaDisplayControllerDelegate?

    #if targetEnvironment(macCatalyst)
    private static let windowWillStartLiveResizeNotification = Notification.Name("NSWindowWillStartLiveResizeNotification")
    private static let windowDidEndLiveResizeNotification = Notification.Name("NSWindowDidEndLiveResizeNotification")
    #endif

    private var isRTL = false

    #if targetEnvironment(macCatalyst)
    override func viewDidLoad() {
        super.viewDidLoad()

        isRTL = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft

        NotificationCenter.default.addObserver(self, selector: #selector(windowWillStartLiveResizing(_:)), name: Self.windowWillStartLiveResizeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidEndLiveResizing(_:)), name: Self.windowDidEndLiveResizeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Self.windowWillStartLiveResizeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Self.windowDidEndLiveResizeNotification, object: nil)
    }
    #else
    override func viewDidLoad() {
        super.viewDidLoad()

        isRTL = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft

        view.contentMode = .center
    }
    #endif

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        guard isLoaded else { return }

        let insets = view.safeAreaInsets.scale(by: view.contentScaleFactor)
        executor.run { core in
            core.setSafeAreaInsets(insets)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard isLoaded else { return }

        if previousTraitCollection?.displayScale != traitCollection.displayScale {
            executor.run { _ in
                self.updateContentScale()
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
    override func prepareGL(_ size: CGSize) -> Bool {
        _ = AppCore.initGL()

        var success = false
        var shouldRetry = true

        while !success && shouldRetry {
            self.dataDirectoryURL = userDefaults.currentDataDirectory()
            self.configFileURL = userDefaults.currentConfigFile()

            FileManager.default.changeCurrentDirectoryPath(self.dataDirectoryURL.url.path)
            DispatchQueue.main.sync {
                AppCore.setLocaleDirectory(self.dataDirectoryURL.url.path + "/locale")
            }

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

            self.core.loadUserDefaultsWithAppDefaults(atPath: Bundle.app.path(forResource: "defaults", ofType: "plist"))
            success = true
        }

        if !success {
            delegate?.celestiaDisplayControllerLoadingFailed(self)
            return false
        }

        core.layoutDirection = isRTL ? .RTL : .LTR
        updateContentScale()
        start()

        isLoaded = true
        delegate?.celestiaDisplayControllerLoadingSucceeded(self)
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
    private func updateContentScale() {
        var viewSafeAreaInsets: UIEdgeInsets = .zero
        var viewScale: CGFloat = 1.0
        var applicationScalingFactor: CGFloat = 1.0

        DispatchQueue.main.sync {
            viewScale = userDefaults[.fullDPI] != false ? self.traitCollection.displayScale : 1
            self.view.contentScaleFactor = viewScale

            #if targetEnvironment(macCatalyst)
            applicationScalingFactor = MacBridge.catalystScaleFactor
            #else
            if #available(iOS 14, *) {
                applicationScalingFactor = ProcessInfo.processInfo.isiOSAppOnMac ? 0.77 : 1
            } else {
                applicationScalingFactor = 1
            }
            #endif

            viewSafeAreaInsets = self.view.safeAreaInsets
        }

        core.setDPI(Int(96.0 * viewScale / applicationScalingFactor))
        core.setSafeAreaInsets(viewSafeAreaInsets.scale(by: viewScale))
        #if targetEnvironment(macCatalyst)
        core.setPickTolerance(4 * viewScale / applicationScalingFactor)
        #else
        core.setPickTolerance(10 * viewScale / applicationScalingFactor)
        #endif

        executor.makeRenderContextCurrent()

        let (font, boldFont) = getInstalledFontFor(locale: AppCore.language)
        core.clearFonts()
        core.setFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9)
        core.setTitleFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15)
        core.setRendererFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9, fontStyle: .normal)
        core.setRendererFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15, fontStyle: .large)
    }
}

extension CelestiaDisplayController {
    var targetGeometry: RenderingTargetGeometry {
        return RenderingTargetGeometry(size: view.frame.size, scale: view.contentScaleFactor)
    }

    private func start() {
        core.tick()
        core.start()
    }
}

typealias FallbackFont = (filePath: String, collectionIndex: Int)

private func getInstalledFontFor(locale: String) -> (font: FallbackFont, boldFont: FallbackFont) {
    let fontDir = Bundle.app.path(forResource: "Fonts", ofType: nil)!
    let fontFallback = [
        "ja": (
            font: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Regular.ttc", collectionIndex: 0),
            boldFont: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Bold.ttc", collectionIndex: 0)
        ),
        "ko": (
            font: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Regular.ttc", collectionIndex: 1),
            boldFont: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Bold.ttc", collectionIndex: 1)
        ),
        "zh_CN": (
            font: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Regular.ttc", collectionIndex: 2),
            boldFont: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Bold.ttc", collectionIndex: 2)
        ),
        "zh_TW": (
            font: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Regular.ttc", collectionIndex: 3),
            boldFont: FallbackFont(filePath: "\(fontDir)/NotoSansCJK-Bold.ttc", collectionIndex: 3)
        ),
        "ar": (
            font: FallbackFont(filePath: "\(fontDir)/NotoSansArabic-Regular.ttf", collectionIndex: 0),
            boldFont: FallbackFont(filePath: "\(fontDir)/NotoSansArabic-Bold.ttf", collectionIndex: 0)
        )
    ]
    let def = (
        font: FallbackFont(filePath: "\(fontDir)/NotoSans-Regular.ttf", collectionIndex: 0),
        boldFont: FallbackFont(filePath: "\(fontDir)/NotoSans-Bold.ttf", collectionIndex: 0)
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
