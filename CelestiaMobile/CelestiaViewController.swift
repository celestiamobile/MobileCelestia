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
}
