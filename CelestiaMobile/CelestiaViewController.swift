//
//  CelestiaViewController.swift
//  CelestiaMobile
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
}

extension CelestiaAction {
    static var allCases: [CelestiaAction] {
        return [.goto, .center]
    }
}

protocol CelestiaViewControllerDelegate: class {
    func celestiaController(_ celestiaController: CelestiaViewController, selection: BodyInfo?, completion: @escaping (CelestiaAction?) -> Void)
}

class CelestiaViewController: GLKViewController {

    private var core: CelestiaAppCore!

    // MARK: rendering
    private var glContext: EAGLContext!
    private var currentSize: CGSize = .zero
    private var ready = false

    // MARK: gesture
    private var oneFingerStartPoint: CGPoint?
    private var twoFingerStartPoint: CGPoint?
    private var currentScale: CGFloat?
    private var edgePanTriggerDistance: CGFloat = 20.0

    weak var celestiaDelegate: CelestiaViewControllerDelegate!

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        guard ready else { return }

        if rect.size != currentSize {
            currentSize = rect.size
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
            core.mouseButtonDown(at: location, modifiers: 0, with: move ? .left : .right)
        case .changed:
            let current = self[keyPath: keyPath]!
            let offset = CGPoint(x: location.x - current.x, y: location.y - current.y)
            self[keyPath: keyPath] = location
            core.mouseMove(by: offset, modifiers: 0, with: move ? .left : .right)
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            core.mouseButtonUp(at: location, modifiers: 0, with: move ? .left : .right)
            self[keyPath: keyPath] = nil
        }
    }

    @objc private func handlePinch(_ pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .possible:
            break
        case .began:
            currentScale = pinch.scale
        case .changed:
            let delta = pinch.scale / currentScale!
            core.mouseWheel(by: (1 - delta) * pinch.view!.bounds.height / 2, modifiers: 0)
            currentScale = pinch.scale
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
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
            view.isUserInteractionEnabled = false
            let sel = core.simulation.selection
            let info = sel.isEmpty ? nil : BodyInfo(selection: sel)
            celestiaDelegate.celestiaController(self, selection: info) { [weak self] (action) in
                guard let self = self else { return }
                defer { self.view.isUserInteractionEnabled = true }
                guard let ac = action else { return }
                self.core.charEnter(ac.rawValue)
            }
        default:
            break
        }
    }
}

extension CelestiaViewController {
    private func setupOpenGL() -> Bool {
        guard let context = EAGLContext(api: .openGLES2) else { return false }

        EAGLContext.setCurrent(context)

        (view as! GLKView).context = context

        glContext = context

        return true
    }

    private func setupCelestia(_ status: @escaping (String) -> Void, _ completion: @escaping (Bool) -> Void) {
        _ = CelestiaAppCore.initGL()

        core = CelestiaAppCore.shared

        DispatchQueue.global().async {
            EAGLContext.setCurrent(self.glContext)
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
        view.addGestureRecognizer(pan1)

        let pan2 = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan2.minimumNumberOfTouches = 2
        pan2.maximumNumberOfTouches = 2
        view.addGestureRecognizer(pan2)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.require(toFail: pan2)
        view.addGestureRecognizer(pinch)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)

        let rightEdge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        rightEdge.edges = .right
        view.addGestureRecognizer(rightEdge)
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

            // FIXME: atmosphere rendering
            self.core.showAtmospheres = false

            self.core.tick()
            self.core.start()

            self.setupGestures()

            self.ready = true

            completion(.success(()))
        }
    }
}
