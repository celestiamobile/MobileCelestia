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
}

extension CelestiaAction {
    static var allCases: [CelestiaAction] {
        return [.goto, .center, .follow, .chase, .syncOrbit, .lock]
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
    private var twoFingerStartPoint: CGPoint?
    private var originalPinchDistance: CGFloat?
    private var currentScale: CGFloat?
    private var edgePanTriggerDistance: CGFloat = 20.0

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

    @objc private func handlePinch(_ pinch: UIPinchGestureRecognizer) {
        if pinch.numberOfTouches < 2 {
            // cancel the gesture recognizer
            pinch.isEnabled = false
            pinch.isEnabled = true
            return
        }
        switch pinch.state {
        case .possible:
            break
        case .began:
            let loc1 = pinch.location(ofTouch: 0, in: pinch.view)
            let loc2 = pinch.location(ofTouch: 1, in: pinch.view)
            originalPinchDistance = hypot(abs(loc1.x - loc2.x), abs(loc1.y - loc2.y))
            currentScale = pinch.scale
        case .changed:
            let delta = pinch.scale / currentScale!
            core.mouseWheel(by: (1 - delta) * originalPinchDistance!, modifiers: 0)
            currentScale = pinch.scale
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            originalPinchDistance = nil
            currentScale = nil
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

    private func setupCelestia(_ status: @escaping (String) -> Void, _ completion: @escaping (Bool) -> Void) {
        _ = CelestiaAppCore.initGL()

        core = CelestiaAppCore.shared

        let context = (self.view as! GLKView).context
        DispatchQueue.global().async {
            EAGLContext.setCurrent(context)
            self.core.startSimulation(configFileName: defaultConfigFile.path, extraDirectories: [extraDirectory].compactMap{$0?.path}) { (st) in
                DispatchQueue.main.async { status(st) }
            }

            guard self.core.startRenderer() else {
                print("Failed to start renderer.")
                DispatchQueue.main.async { completion(false) }
                return
            }

            self.core.loadUserDefaultsWithAppDefaults(atPath: Bundle.main.path(forResource: "defaults", ofType: "plist"))
            DispatchQueue.main.async { completion(true) }
        }
    }

    private func setupGestures() {
        let pan1 = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan1.minimumNumberOfTouches = 1
        pan1.maximumNumberOfTouches = 1
        pan1.delegate = self
        view.addGestureRecognizer(pan1)

        let pan2 = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan2.minimumNumberOfTouches = 2
        pan2.maximumNumberOfTouches = 2
        pan2.delegate = self
        view.addGestureRecognizer(pan2)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        pinch.require(toFail: pan2)
        view.addGestureRecognizer(pinch)

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
    func load(_ status: @escaping (String) -> Void, _ completion: @escaping (Result<Void, CelestiaLoadingError>) -> Void) {
        guard setupOpenGL() else {
            completion(.failure(.openGLError))
            return
        }
        setupCelestia({ (st) in
            status(st)
        }) { (success) in
            guard success else {
                completion(.failure(.celestiaError))
                return
            }

            self.core.tick()
            self.core.start()

            self.setupGestures()

            self.setupDisplayLink()

            self.ready = true

            completion(.success(()))
        }
    }
}

extension CelestiaViewController {
    func receive(action: CelestiaAction) {
        self.core.receive(action)
    }

    func select(_ bodyInfo: BodyInfo) {
        self.core.selection = bodyInfo
    }

    func screenshot() -> UIImage {
        return UIGraphicsImageRenderer(size: view.bounds.size).image { (_) in
            self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: false)
        }
    }
}
