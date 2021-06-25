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
    private var core: CelestiaAppCore!

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

    #if targetEnvironment(macCatalyst)
    override func viewDidLoad() {
        super.viewDidLoad()

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

        view.contentMode = .center
    }
    #endif

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        guard isLoaded else { return }

        let insets = view.safeAreaInsets.scale(by: view.contentScaleFactor)
        core.run { core in
            core.setSafeAreaInsets(insets)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard isLoaded else { return }

        if previousTraitCollection?.displayScale != traitCollection.displayScale {
            core.run { [weak self] _ in
                self?.updateContentScale()
            }
        }
    }

    #if targetEnvironment(macCatalyst)
    @objc private func windowWillStartLiveResizing(_ notification: Notification) {
        guard let window = view.window else { return }

        if notification.object as? NSObject == MacBridge.nsWindowForUIWindow(window) {
            isPaused = true
        }
    }

    @objc private func windowDidEndLiveResizing(_ notification: Notification) {
        guard let window = view.window else { return }

        if notification.object as? NSObject == MacBridge.nsWindowForUIWindow(window) {
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
    override func prepareGL(_ size: CGSize) {
        _ = CelestiaAppCore.initGL()
        core = CelestiaAppCore.shared

        var success = false
        var shouldRetry = true

        while !success && shouldRetry {
            self.dataDirectoryURL = currentDataDirectory()
            self.configFileURL = currentConfigFile()

            FileManager.default.changeCurrentDirectoryPath(self.dataDirectoryURL.url.path)
            CelestiaAppCore.setLocaleDirectory(self.dataDirectoryURL.url.path + "/locale")

            guard self.core.startSimulation(configFileName: self.configFileURL.url.path, extraDirectories: [extraDirectory].compactMap{$0?.path}, progress: { (st) in
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
            return
        }

        CelestiaAppCore.renderViewController = self

        updateContentScale()
        start()

        isLoaded = true
        delegate?.celestiaDisplayControllerLoadingSucceeded(self)
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

private extension CelestiaAppCore {
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
            viewScale = UserDefaults.app[.fullDPI] != false ? self.traitCollection.displayScale : 1
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

        CelestiaAppCore.makeRenderContextCurrent()

        let locale = LocalizedString("LANGUAGE", "celestia")
        let (font, boldFont) = getInstalledFontFor(locale: locale)
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
    func screenshot() -> UIImage {
        return UIGraphicsImageRenderer(size: view.bounds.size, format: UIGraphicsImageRendererFormat(for: UITraitCollection(displayScale: view.contentScaleFactor))).image { (_) in
            self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: false)
        }
    }
}

private extension UIEdgeInsets {
    func scale(by factor: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: top * factor, left: left * factor, bottom: bottom * factor, right: right * factor)
    }
}

extension CelestiaAppCore {
    fileprivate static var renderQueue: DispatchQueue? {
        return renderViewController?.glView?.renderQueue
    }

    fileprivate static weak var renderViewController: AsyncGLViewController?

    func run(_ task: @escaping (CelestiaAppCore) -> Void) {
        guard let queue = Self.renderQueue else { return }
        queue.async { [weak self] in
            guard let self = self else { return }
            task(self)
        }
    }

    static func makeRenderContextCurrent() {
        Self.renderViewController?.makeRenderContextCurrent()
    }

    func get<T>(_ task: (CelestiaAppCore) -> T) -> T {
        guard let queue = Self.renderQueue else { fatalError() }
        var item: T?
        queue.sync { [weak self] in
            guard let self = self else { return }
            item = task(self)
        }
        guard let returnItem = item else { fatalError() }
        return returnItem
    }

    func receive(_ action: CelestiaAction) {
        if textEnterMode != .normal {
            textEnterMode = .normal
        }
        charEnter(action.rawValue)
    }

    func receiveAsync(_ action: CelestiaAction, completion: (() -> Void)? = nil) {
        run {
            $0.receive(action)
            completion?()
        }
    }

    func selectAndReceiveAsync(_ selection: CelestiaSelection, action: CelestiaAction) {
        run {
            $0.simulation.selection = selection
            $0.receive(action)
        }
    }

    func charEnterAsync(_ char: Int8) {
        run {
            $0.charEnter(char)
        }
    }

    func getSelectionAsync(_ completion: @escaping (CelestiaSelection, CelestiaAppCore) -> Void) {
        run { core in
            completion(core.simulation.selection, core)
        }
    }

    func markAsync(_ selection: CelestiaSelection, markerType: CelestiaMarkerRepresentation) {
        run { core in
            core.simulation.universe.mark(selection, with: markerType)
            core.showMarkers = true
        }
    }

    func setValueAsync(_ value: Any?, forKey key: String, completionOnMainQueue: (() -> Void)? = nil) {
        run { core in
            core.setValue(value, forKey: key)
            DispatchQueue.main.async {
                completionOnMainQueue?()
            }
        }
    }
}
