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

#if !USE_MGL
import GLKit
#endif

protocol CelestiaDisplayControllerDelegate: class {
    func celestiaDisplayControllerWillDisplay(_ celestiaDisplayController: CelestiaDisplayController)
}

class CelestiaDisplayController: UIViewController {

    private var core: CelestiaAppCore!

    // MARK: rendering
    private var currentSize: CGSize = .zero
    private var ready = false
    private var displayLink: CADisplayLink?
    private var displaySource: DispatchSourceUserDataAdd?

    #if USE_MGL
    private lazy var glView = MGLKView(frame: .zero)
    #else
    private lazy var glView = GLKView(frame: .zero)
    #endif

    // MARK: gesture
    private var oneFingerStartPoint: CGPoint?
    private var currentPanDistance: CGFloat?

    private var dataDirectoryURL: UniformedURL!
    private var configFileURL: UniformedURL!

    weak var delegate: CelestiaDisplayControllerDelegate?

    override func loadView() {
        glView.translatesAutoresizingMaskIntoConstraints = false
        setupOpenGL()
        glView.delegate = self

        view = glView
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        guard ready else { return }

        core?.setSafeAreaInsets(view.safeAreaInsets.scale(by: glView.contentScaleFactor))
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.displayScale != traitCollection.displayScale {
            updateContentScale()
        }
    }
}

private extension CelestiaAppCore {
    func setSafeAreaInsets(_ safeAreaInsets: UIEdgeInsets) {
        setSafeAreaInsets(left: safeAreaInsets.left, top: safeAreaInsets.top, right: safeAreaInsets.right, bottom: safeAreaInsets.bottom)
    }
}

#if USE_MGL
extension CelestiaDisplayController: MGLKViewDelegate {
    func mglkView(_ view: MGLKView!, drawIn rect: CGRect) {
        guard ready else { return }

        let size = view.drawableSize
        if size != currentSize {
            currentSize = size
            core.resize(to: currentSize)
        }

        core.draw()
        core.tick()
    }
}
#else
extension CelestiaDisplayController: GLKViewDelegate {
    func glkView(_ view: GLKView, drawIn rect: CGRect) {
        guard ready else { return }

        let size = CGSize(width: view.drawableWidth, height: view.drawableHeight)
        if size != currentSize {
            currentSize = size
            core.resize(to: currentSize)
        }

        core.draw()
        core.tick()
    }
}
#endif

extension CelestiaDisplayController {
    @objc private func handleDisplayLink(_ sender: CADisplayLink) {
        displaySource?.add(data: 1)
    }

    private func displaySourceCallback() {
        delegate?.celestiaDisplayControllerWillDisplay(self)
        glView.display()
    }
}

extension CelestiaDisplayController {
    @discardableResult private func setupOpenGL() -> Bool {
        #if USE_MGL
        let context = MGLContext(api: kMGLRenderingAPIOpenGLES2)
        MGLContext.setCurrent(context)

        glView.context = context
        glView.drawableDepthFormat = MGLDrawableDepthFormat24

        glView.drawableMultisample = UserDefaults.app[.msaa] == true ? MGLDrawableMultisample4X : MGLDrawableMultisampleNone
        #else
        let context = EAGLContext(api: .openGLES2)!

        EAGLContext.setCurrent(context)

        glView.context = context
        glView.enableSetNeedsDisplay = false
        glView.drawableDepthFormat = .format24

        glView.drawableMultisample = UserDefaults.app[.msaa] == true ? .multisample4X : .multisampleNone
        #endif

        // Set initial scale from user defaults
        let viewScale = UserDefaults.app[.fullDPI] == true ? traitCollection.displayScale : 1
        glView.contentScaleFactor = viewScale

        return true
    }

    private func setupCelestia(statusUpdater: @escaping (String) -> Void, errorHandler: @escaping () -> Bool, completionHandler: @escaping (Bool) -> Void) {

        #if !USE_MGL
        let context = glView.context
        EAGLContext.setCurrent(context)
        #endif

        _ = CelestiaAppCore.initGL()

        core = CelestiaAppCore.shared

        DispatchQueue.global().async { [unowned self] in
            #if !USE_MGL
            EAGLContext.setCurrent(context)
            #endif

            var success = false
            var shouldRetry = true

            while !success && shouldRetry {
                self.dataDirectoryURL = currentDataDirectory()
                self.configFileURL = currentConfigFile()

                FileManager.default.changeCurrentDirectoryPath(self.dataDirectoryURL.url.path)
                CelestiaAppCore.setLocaleDirectory(self.dataDirectoryURL.url.path + "/locale")

                guard self.core.startSimulation(configFileName: self.configFileURL.url.path, extraDirectories: [extraDirectory].compactMap{$0?.path}, progress: { (st) in
                    DispatchQueue.main.async { statusUpdater(st) }
                }) else {
                    shouldRetry = errorHandler()
                    continue
                }

                guard self.core.startRenderer() else {
                    print("Failed to start renderer.")
                    shouldRetry = errorHandler()
                    continue
                }

                self.core.loadUserDefaultsWithAppDefaults(atPath: Bundle.main.path(forResource: "defaults", ofType: "plist"))
                success = true
            }

            DispatchQueue.main.async { completionHandler(success) }
        }
    }

    private func setupDisplayLink() {
        displaySource = DispatchSource.makeUserDataAddSource(queue: .main)
        displaySource?.setEventHandler() { [weak self] in
            self?.displaySourceCallback()
        }
        displaySource?.resume()

        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink?.add(to: .current, forMode: .default)
    }

    private func updateContentScale() {
        let viewScale = UserDefaults.app[.fullDPI] == true ? traitCollection.displayScale : 1
        glView.contentScaleFactor = viewScale

        #if targetEnvironment(macCatalyst)
        let applicationScalingFactor: CGFloat = MacBridge.catalystScaleFactor
        #else
        let applicationScalingFactor: CGFloat = 1
        #endif

        core.setDPI(Int(96.0 * glView.contentScaleFactor / applicationScalingFactor))
        core.setSafeAreaInsets(view.safeAreaInsets.scale(by: glView.contentScaleFactor))
    }
}

extension CelestiaDisplayController {
    var targetGeometry: RenderingTargetGeometry {
        return RenderingTargetGeometry(size: glView.frame.size, scale: glView.contentScaleFactor)
    }

    func load(statusUpdater: @escaping (String) -> Void, errorHandler: @escaping () -> Bool, completionHandler: @escaping (CelestiaLoadingResult) -> Void) {
        setupCelestia(statusUpdater: { (st) in
            statusUpdater(st)
        }, errorHandler: {
            return errorHandler()
        }, completionHandler: { (success) in
            guard success else {
                completionHandler(.failure(.celestiaError))
                return
            }

            self.start()

            self.setupDisplayLink()

            self.ready = true

            completionHandler(.success(()))
        })
    }

    private func start() {
        updateContentScale()

        let locale = LocalizedString("LANGUAGE", "celestia")
        if let (font, boldFont) = getInstalledFontFor(locale: locale) {
            core.setFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9)
            core.setTitleFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15)
            core.setRendererFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9, fontStyle: .normal)
            core.setRendererFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15, fontStyle: .large)
        } else if let font = GetFontForLocale(locale, .system),
            let boldFont = GetFontForLocale(locale, .emphasizedSystem) {
            core.setFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9)
            core.setTitleFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15)
            core.setRendererFont(font.filePath, collectionIndex: font.collectionIndex, fontSize: 9, fontStyle: .normal)
            core.setRendererFont(boldFont.filePath, collectionIndex: boldFont.collectionIndex, fontSize: 15, fontStyle: .large)
        }

        core.tick()
        core.start()
    }
}

private func getInstalledFontFor(locale: String) -> (font: FallbackFont, boldFont: FallbackFont)? {
    guard let fontDir = Bundle.main.path(forResource: "Fonts", ofType: nil) else { return nil }
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
        return UIGraphicsImageRenderer(size: glView.bounds.size, format: UIGraphicsImageRendererFormat(for: UITraitCollection(displayScale: glView.contentScaleFactor))).image { (_) in
            self.glView.drawHierarchy(in: self.glView.bounds, afterScreenUpdates: false)
        }
    }
}

private extension UIEdgeInsets {
    func scale(by factor: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: top * factor, left: left * factor, bottom: bottom * factor, right: right * factor)
    }
}
