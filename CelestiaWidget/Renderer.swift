//
// Renderer.swift
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
import OpenGLES

class Renderer {
    static var context: EAGLContext?
    static var core: CelestiaAppCore?
    static var fbos = [String: CelestiaFrameBuffer]()

    static let mutex = NSLock()

    static func render(size: CGSize, scale: CGFloat, url: String) -> UIImage? {
        let drawableSize = size.applying(CGAffineTransform(scaleX: scale, y: scale))

        mutex.lock()
        defer { mutex.unlock() }

        if context == nil {
            // Create context and load Celestia
            let glContext = EAGLContext(api: .openGLES2)
            if glContext == nil { return nil }
            context = glContext
        } else {
            print("context exists")
        }
        EAGLContext.setCurrent(context)

        if core == nil {
            // Load special CFG to save memory
            let cfgPath = Bundle.main.path(forResource: "celestia", ofType: "cfg")!
            let dataDirectory = defaultDataDirectory.path
            FileManager.default.changeCurrentDirectoryPath(dataDirectory)

            CelestiaAppCore.initGL()

            let newCore = CelestiaAppCore()
            guard newCore.startSimulation(configFileName: cfgPath, extraDirectories: nil, progress: { _ in }) else {
                return nil
            }
            guard newCore.startRenderer() else { return nil }

            newCore.loadUserDefaultsWithAppDefaults(atPath: Bundle.app.path(forResource: "defaults", ofType: "plist"))

            newCore.start()
            core = newCore
        }

        let key = "\(Int(drawableSize.width))-\(Int(drawableSize.height))"
        var fbo = fbos[key]
        if fbo == nil {
            fbo = CelestiaFrameBuffer(size: drawableSize, attachments: [.color, .depth])
            fbos[key] = fbo
        }

        fbo!.bind()
        defer { fbo!.unbind() }

        core!.resize(to: drawableSize)
        core!.go(to: url)
        core!.draw()

        let path = NSTemporaryDirectory() + "\(UUID().uuidString).png"
        guard core!.screenshot(to: path, type: .PNG) else { return nil }
        guard let originalImage = UIImage(contentsOfFile: path) else { return nil }
        return UIImage(cgImage: originalImage.cgImage!, scale: scale, orientation: originalImage.imageOrientation)
    }
}
