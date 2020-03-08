//
//  CelestiaViewController.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/2/20.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit
import CelestiaCore
import GLKit

enum CelestiaLoadingError: Error {
    case openGLError
    case celestiaError
}

enum CelestiaAction: Int8 {
    case goto = 103
    case center = 99
    case playpause = 32
    case backward = 107
    case forward = 108
    case currentTime = 33
    case syncOrbit = 121
    case lock = 58
    case chase = 34
    case follow = 102
    case runDemo = 100
}

extension CelestiaAction {
    static var allCases: [CelestiaAction] {
        return [.goto, .center, .follow, .chase, .syncOrbit, .lock]
    }
}

extension CelestiaAppCore {
    func receive(_ action: CelestiaAction) {
        charEnter(action.rawValue)
    }
}

protocol CelestiaViewControllerDelegate: class {
    func celestiaController(_ celestiaController: CelestiaViewController, selection: BodyInfo?)
}

class CelestiaViewController: UIViewController {

    private var core: CelestiaAppCore!

    // MARK: rendering
    private var currentSize: CGSize = .zero
    private var ready = false
    private var displayLink: CADisplayLink?

    // MARK: gesture
    private var oneFingerStartPoint: CGPoint?
    private var currentPanDistance: CGFloat?
    private var currentPanCenter: CGPoint?
    private var twoFingerStartPoint: CGPoint?
    private var originalPinchDistance: CGFloat?
    private var currentScale: CGFloat?
    private var edgePanTriggerDistance: CGFloat = 20.0

    private var dataDirectoryURL: UniformedURL!
    private var configFileURL: UniformedURL!

    weak var celestiaDelegate: CelestiaViewControllerDelegate!

    override func loadView() {
        let glView = GLKView(frame: .zero)
        glView.delegate = self
        view = glView
    }
}

extension CelestiaViewController: GLKViewDelegate {
    func glkView(_ view: GLKView, drawIn rect: CGRect) {
        guard ready else { return }

        if view.bounds.size != currentSize {
            currentSize = view.bounds.size
            core.resize(to: currentSize)
        }

        core.draw()
        core.tick()
    }
}

extension CelestiaViewController {
    @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
        let move = pan.minimumNumberOfTouches == 1
        if pan.numberOfTouches != pan.minimumNumberOfTouches {
            // cancel the gesture recognizer
            pan.isEnabled = false
            pan.isEnabled = true
            return
        }
        let keyPath = move ? \CelestiaViewController.oneFingerStartPoint : \CelestiaViewController.twoFingerStartPoint
        let location = pan.location(in: view)
        switch pan.state {
        case .possible:
            break
        case .began:
            self[keyPath: keyPath] = location
            core.mouseButtonDown(at: location, modifiers: 0, with: move ? .right : .left)
        case .changed:
            let current = self[keyPath: keyPath]!
            let offset = CGPoint(x: location.x - current.x, y: location.y - current.y)
            self[keyPath: keyPath] = location
            core.mouseMove(by: offset, modifiers: 0, with: move ? .right : .left)
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            core.mouseButtonUp(at: location, modifiers: 0, with: move ? .right : .left)
            self[keyPath: keyPath] = nil
        }
    }

    @objc private func handlePan2AndPinch(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .possible:
            break
        case .began:
            if gesture.numberOfTouches < 2 {
                // cancel the gesture recognizer
                gesture.isEnabled = false
                gesture.isEnabled = true
                break
            }
            let point1 = gesture.location(ofTouch: 0, in: view)
            let point2 = gesture.location(ofTouch: 1, in: view)
            let length = hypot(abs(point1.x - point2.x), abs(point1.y - point2.y))
            let center = CGPoint(x: (point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)
            currentPanDistance = length
            currentPanCenter = center
            core.mouseButtonDown(at: center, modifiers: 0, with: .left)
        case .changed:
            if gesture.numberOfTouches < 2 {
                // cancel the gesture recognizer
                gesture.isEnabled = false
                gesture.isEnabled = true
                break
            }
            let point1 = gesture.location(ofTouch: 0, in: view)
            let point2 = gesture.location(ofTouch: 1, in: view)
            let length = hypot(abs(point1.x - point2.x), abs(point1.y - point2.y))
            let center = CGPoint(x: (point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)
            core.mouseMove(by: CGPoint(x: center.x - currentPanCenter!.x,
                                       y: center.y - currentPanCenter!.y),
                           modifiers: 0, with: .left)
            let delta = length / currentPanDistance!
            // FIXME: 8 is a magic number
            core.mouseWheel(by: (1 - delta) * currentPanDistance! / 8, modifiers: 0)
            currentPanDistance = length
            currentPanCenter = center
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            if let point = currentPanCenter {
                core.mouseButtonUp(at: point, modifiers: 0, with: .left)
            }
            currentPanDistance = nil
            currentPanCenter = nil
        }
    }

    @objc private func handleTap(_ tap: UITapGestureRecognizer) {
        switch tap.state {
        case .ended:
            let location = tap.location(in: view)
            core.mouseButtonDown(at: location, modifiers: 0, with: .left)
            core.mouseButtonUp(at: location, modifiers: 0, with: .left)
        default:
            break
        }
    }

    @objc private func handleEdgePan(_ pan: UIScreenEdgePanGestureRecognizer) {
        switch pan.state {
        case .ended:
            let sel = core.simulation.selection
            let info = sel.isEmpty ? nil : BodyInfo(selection: sel)
            celestiaDelegate.celestiaController(self, selection: info)
        default:
            break
        }
    }
}

extension CelestiaViewController {
    @objc private func handleDisplayLink(_ sender: CADisplayLink) {
        (view as! GLKView).display()
    }
}

extension CelestiaViewController {
    private func setupOpenGL() -> Bool {
        guard let context = EAGLContext(api: .openGLES2) else { return false }

        let view = self.view as! GLKView

        EAGLContext.setCurrent(context)

        view.context = context
        view.enableSetNeedsDisplay = false
        view.drawableDepthFormat = .format24

        return true
    }

    private func setupCelestia(statusUpdater: @escaping (String) -> Void, errorHandler: @escaping () -> Bool, completionHandler: @escaping (Bool) -> Void) {
        _ = CelestiaAppCore.initGL()

        core = CelestiaAppCore.shared

        let context = (self.view as! GLKView).context
        DispatchQueue.global().async { [unowned self] in
            var success = false
            var shouldRetry = true

            EAGLContext.setCurrent(context)

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

    private func setupGestures() {
        let pan1 = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan1.minimumNumberOfTouches = 1
        pan1.maximumNumberOfTouches = 1
        pan1.delegate = self
        view.addGestureRecognizer(pan1)

        let pan2 = UIPanGestureRecognizer(target: self, action: #selector(handlePan2AndPinch(_:)))
        pan2.minimumNumberOfTouches = 2
        pan2.maximumNumberOfTouches = 2
        pan2.delegate = self
        view.addGestureRecognizer(pan2)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.delegate = self
        view.addGestureRecognizer(tap)

        let rightEdge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        rightEdge.edges = .right
        pan1.require(toFail: rightEdge)
        view.addGestureRecognizer(rightEdge)
    }

    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink?.add(to: .current, forMode: .default)
    }
}

extension CelestiaViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var area = gestureRecognizer.view!.bounds
        if #available(iOS 11.0, *) {
            area = area.inset(by: gestureRecognizer.view!.safeAreaInsets)
        }
        // reserve area
        area = area.insetBy(dx: 16, dy: 16)
        if !area.contains(gestureRecognizer.location(in: gestureRecognizer.view)) {
            return false
        }
        if gestureRecognizer is UIPinchGestureRecognizer {
            return gestureRecognizer.numberOfTouches == 2
        }
        return true
    }
}

extension CelestiaViewController {
    func load(statusUpdater: @escaping (String) -> Void, errorHandler: @escaping () -> Bool, completionHandler: @escaping (Result<Void, CelestiaLoadingError>) -> Void) {
        guard setupOpenGL() else {
            completionHandler(.failure(.openGLError))
            return
        }
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

            self.setupGestures()

            self.setupDisplayLink()

            self.ready = true

            completionHandler(.success(()))
        })
    }

    private func start() {
        core.tick()
        core.start()
    }
}

extension CelestiaViewController {
    func receive(action: CelestiaAction) {
        core.receive(action)
    }

    func select(_ bodyInfo: BodyInfo) {
        core.selection = bodyInfo
    }

    var currentURL: URL {
        return URL(string: core.currentURL)!
    }

    func screenshot() -> UIImage {
        return UIGraphicsImageRenderer(size: view.bounds.size).image { (_) in
            self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: false)
        }
    }

    func openURL(_ url: UniformedURL) {
        if url.url.isFileURL {
            core.runScript(at: url.url.path)
        } else {
            core.go(to: url.url.absoluteString)
        }
    }
}
