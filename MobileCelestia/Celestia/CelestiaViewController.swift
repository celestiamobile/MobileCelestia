//
// CelestiaViewController.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import AsyncGL
import UIKit
import CelestiaCore

enum CelestiaLoadingError: Error {
    case openGLError
    case celestiaError
}

struct RenderingTargetGeometry {
    let size: CGSize
    let scale: CGFloat
}

typealias CelestiaLoadingResult = Result<Void, CelestiaLoadingError>

@MainActor
protocol CelestiaControllerDelegate: AnyObject {
    func celestiaController(_ celestiaController: CelestiaViewController, loadingStatusUpdated status: String)
    func celestiaControllerLoadingFailedShouldRetry(_ celestiaController: CelestiaViewController) -> Bool
    func celestiaControllerLoadingFailed(_ celestiaController: CelestiaViewController)
    func celestiaControllerLoadingSucceeded(_ celestiaController: CelestiaViewController)
    func celestiaController(_ celestiaController: CelestiaViewController, requestShowActionMenuWithSelection selection: Selection)
    func celestiaController(_ celestiaController: CelestiaViewController, requestShowInfoWithSelection selection: Selection)
    func celestiaController(_ celestiaController: CelestiaViewController, requestWebInfo webURL: URL)
}

class CelestiaViewController: UIViewController {
    weak var delegate: CelestiaControllerDelegate!

    private let displayController: CelestiaDisplayController
    private var interactionController: CelestiaInteractionController?

    private lazy var auxiliaryWindows = [UIWindow]()

    private(set) var appScreen: UIScreen
    private(set) var displayScreen: UIScreen
    private(set) var isMirroring: Bool

    init(screen: UIScreen, executor: CelestiaExecutor, userDefaults: UserDefaults) {
        appScreen = screen
        displayScreen = screen
        isMirroring = false
        #if targetEnvironment(macCatalyst)
        let api = AsyncGLAPI.openGLLegacy
        #else
        let api = AsyncGLAPI.openGLES2
        #endif
        displayController = CelestiaDisplayController(msaaEnabled: userDefaults[.msaa] == true, screen: screen, initialFrameRate: userDefaults[.frameRate] ?? 60, api: api, executor: executor)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let container = UIView()
        container.backgroundColor = .darkBackground
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        displayController.delegate = self
        install(displayController)

        NotificationCenter.default.addObserver(self, selector: #selector(windowDidMoveToScreenNotification(_:)), name: NSNotification.Name("UIWindowDidMoveToScreenNotification"), object: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if #available(iOS 13.4, *), let key = presses.first?.key {
            interactionController?.keyDown(with: key.input, modifiers: UInt(key.modifierFlags.rawValue))
        } else {
            super.pressesBegan(presses, with: event)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if #available(iOS 13.4, *), let key = presses.first?.key {
            interactionController?.keyUp(with: key.input, modifiers: UInt(key.modifierFlags.rawValue))
        } else {
            super.pressesEnded(presses, with: event)
        }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if #available(iOS 13.4, *), let key = presses.first?.key {
            interactionController?.keyUp(with: key.input, modifiers: UInt(key.modifierFlags.rawValue))
        } else {
            super.pressesCancelled(presses, with: event)
        }
    }
}

extension CelestiaViewController {
    @objc private func windowDidMoveToScreenNotification(_ notification: Notification) {
        guard let window = notification.object as? UIWindow else { return }
        guard let screen = notification.userInfo?["UIWindowNewScreenUserInfoKey"] as? UIScreen else { return }

        if view.window == window {
            if appScreen != screen {
                appScreen = screen
            }
        }
        if displayController.view.window == window {
            if displayScreen != screen {
                setDisplayScreen(screen)
            }
        }
    }
}

extension CelestiaViewController: CelestiaInteractionControllerDelegate {
    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestShowActionMenuWithSelection selection: Selection) {
        delegate?.celestiaController(self, requestShowActionMenuWithSelection: selection)
    }

    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestShowInfoWithSelection selection: Selection) {
        delegate?.celestiaController(self, requestShowInfoWithSelection: selection)
    }

    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestWebInfo webURL: URL) {
        delegate?.celestiaController(self, requestWebInfo: webURL)
    }
}

extension CelestiaViewController: CelestiaDisplayControllerDelegate {
    nonisolated func celestiaDisplayControllerLoadingSucceeded(_ celestiaDisplayController: CelestiaDisplayController) {
        Task.detached { @MainActor in
            let interactionController = CelestiaInteractionController()
            interactionController.delegate = self
            interactionController.targetProvider = self
            self.install(interactionController)
            self.interactionController = interactionController
            if self.isMirroring {
                interactionController.startMirroring()
            }
            self.delegate?.celestiaControllerLoadingSucceeded(self)
        }
    }

    nonisolated func celestiaDisplayControllerLoadingFailedShouldRetry(_ celestiaDisplayController: CelestiaDisplayController) -> Bool {
        return DispatchQueue.main.sync {
            return delegate.celestiaControllerLoadingFailedShouldRetry(self)
        }
    }

    nonisolated func celestiaDisplayControllerLoadingFailed(_ celestiaDisplayController: CelestiaDisplayController) {
        Task.detached { @MainActor in
            self.delegate?.celestiaControllerLoadingFailed(self)
        }
    }

    nonisolated func celestiaDisplayController(_ celestiaDisplayController: CelestiaDisplayController, loadingStatusUpdated status: String) {
        Task.detached { @MainActor in
            self.delegate.celestiaController(self, loadingStatusUpdated: status)
        }
    }
}

extension CelestiaViewController {
    func openURL(_ url: UniformedURL) {
        interactionController?.openURL(url)
    }

    func updateFrameRate(_ newFrameRate: Int) {
        displayController.setPreferredFramesPerSecond(newFrameRate)
    }

    func move(to window: UIWindow, screen: UIScreen) {
        // Only move the display controller to the new screen
        displayController.remove()
        let dummyViewController = UIViewController()
        dummyViewController.view.backgroundColor = .black
        window.rootViewController = dummyViewController
        setDisplayScreen(screen)
        dummyViewController.install(displayController)
        interactionController?.startMirroring()
        isMirroring = true
    }

    func moveBack(from window: UIWindow) {
        // Only move back when it has the display view controller
        guard let rootViewController = window.rootViewController, rootViewController.children.contains(displayController) else { return }
        displayController.remove()
        window.rootViewController = nil
        setDisplayScreen(appScreen)
        install(displayController)
        view.sendSubviewToBack(displayController.view)
        isMirroring = false
        interactionController?.stopMirroring()
    }

    #if !targetEnvironment(macCatalyst)
    func move(to screen: UIScreen) -> Bool {
        let newWindow = UIWindow(frame: screen.bounds)
        // Find the window scene associated with the screen...
        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.screen == screen }) else {
            return false
        }
        newWindow.windowScene = windowScene
        auxiliaryWindows.append(newWindow)
        move(to: newWindow, screen: screen)
        newWindow.isHidden = false
        return true
    }

    func moveBack(from screen: UIScreen) -> Bool {
        guard let windowIndex = auxiliaryWindows.firstIndex(where: { $0.windowScene?.screen == screen }) else {
            // No window with this screen is found
            return false
        }
        let window = auxiliaryWindows.remove(at: windowIndex)
        moveBack(from: window)
        return true
    }
    #endif

    private func setDisplayScreen(_ screen: UIScreen) {
        displayScreen = screen
        displayController.setScreen(screen)
    }
}

extension CelestiaViewController: RenderingTargetInformationProvider {
    var targetGeometry: RenderingTargetGeometry {
        return displayController.targetGeometry
    }

    var targetContents: Any? {
        return displayController.screenshot()
    }
}

@available(iOS 13.4, *)
private extension UIKey {
    var input: String? {
        let c = characters
        if c.count > 0 {
            return c
        }
        return charactersIgnoringModifiers
    }
}
