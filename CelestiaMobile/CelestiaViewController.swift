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

class CelestiaViewController: GLKViewController {

    private var core: CelestiaAppCore!
    private var glContext: EAGLContext!

    private var currentSize: CGSize = .zero

    private lazy var statusLabel: UILabel = UILabel()

    private var ready = false

    private var oneFingerStartPoint: CGPoint?
    private var twoFingerStartPoint: CGPoint?
    private var currentScale: CGFloat?

    override func viewDidLoad() {
        super.viewDidLoad()

        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: statusLabel.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
        ])

        guard setupOpenGL() else {
            print("Failed to setup OpenGL")
            return
        }

        setupCelestia { (success) in
            guard success else {
                print("Failed to setup Celestia")
                return
            }
            self.statusLabel.text = nil

            self.core.showAtmospheres = false

            self.core.tick()
            self.core.start()

            self.ready = true

            self.setupGestures()
        }
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        guard ready else { return }

        if rect.size != currentSize {
            currentSize = rect.size
            core.resize(to: currentSize)
        }

        core.draw()
        core.tick()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

extension CelestiaViewController {
    @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
        let move = pan.minimumNumberOfTouches == 1
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
}

extension CelestiaViewController {
    private func setupOpenGL() -> Bool {
        guard let context = EAGLContext(api: .openGLES2) else { return false }

        EAGLContext.setCurrent(context)

        (view as! GLKView).context = context

        glContext = context

        return true
    }

    private func setupCelestia(_ completion: @escaping (Bool) -> Void) {
        _ = CelestiaAppCore.initGL()

        core = CelestiaAppCore()

        DispatchQueue.global().async {
            EAGLContext.setCurrent(self.glContext)
            self.core.startSimulation(configFileName: defaultConfigFile.path, extraDirectories: [extraDirectory].compactMap{$0?.path}) { (status) in
                DispatchQueue.main.async { self.statusLabel.text = status }
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
    }
}
