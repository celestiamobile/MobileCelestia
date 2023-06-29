//
// FavoriteView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import CelestiaUI
import SwiftUI

struct FavoriteView: UIViewControllerRepresentable {
    typealias UIViewControllerType = FavoriteCoordinatorController

    @Environment(XRRenderer.self) private var renderer

    private let userDirectory: URL

    init(userDirectory: URL) {
        self.userDirectory = userDirectory
    }

    func makeUIViewController(context: Context) -> FavoriteCoordinatorController {
        return FavoriteCoordinatorController(executor: renderer, root: .main) {
            let path = userDirectory.appending(component: "scripts").path(percentEncoded: false)
            var isDir: ObjCBool = false
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: path, isDirectory: &isDir) {
                return isDir.boolValue ? path : nil
            } else {
                do {
                    try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
                    return path
                } catch {
                    return nil
                }
            }
        } selected: { object in
            if let url = object as? URL {
                self.renderer.enqueue { core in
                    if url.isFileURL {
                        core.runScript(at: url.path(percentEncoded: false))
                    } else {
                        core.go(to: url.absoluteString)
                    }
                }
            } else if let destination = object as? Destination {
                self.renderer.enqueue { $0.simulation.goToDestination(destination) }
            }
        } share: { object, viewController in
            guard let node = object as? BookmarkNode, node.isLeaf else { return }
            viewController.shareURL(node.url, placeholder: node.name)
        } textInputHandler: { viewController, title, text in
            return await viewController.getTextInput(title, text: text)
        }
    }

    func updateUIViewController(_ uiViewController: FavoriteCoordinatorController, context: Context) {
    }
}
