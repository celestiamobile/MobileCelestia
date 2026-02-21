// CelestiaViewController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import AsyncGL
import CelestiaCore
import CelestiaFoundation
import CelestiaUI
import Combine
import UIKit

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
    func celestiaController(_ celestiaController: CelestiaViewController, loadingFailedShouldRetry shouldRetry: @escaping (Bool) -> Void)
    func celestiaControllerLoadingFailed(_ celestiaController: CelestiaViewController)
    func celestiaControllerLoadingSucceeded(_ celestiaController: CelestiaViewController)
    func celestiaControllerRequestShowActionMenu(_ celestiaController: CelestiaViewController)
    func celestiaControllerRequestShowSearch(_ celestiaController: CelestiaViewController)
    func celestiaController(_ celestiaController: CelestiaViewController, requestShowInfoWithSelection selection: Selection)
    func celestiaController(_ celestiaController: CelestiaViewController, requestShowSubsystemWithSelection selection: Selection)
    func celestiaController(_ celestiaController: CelestiaViewController, requestWebInfo webURL: URL)
    func celestiaControllerCanAcceptKeyEvents(_ celestiaController: CelestiaViewController) -> Bool
    func celestiaControllerRequestGo(_ celestiaController: CelestiaViewController)
}

class CelestiaViewController: UIViewController {
    weak var delegate: CelestiaControllerDelegate!

    private let displayController: CelestiaDisplayController
    private var interactionController: CelestiaInteractionController?

    private lazy var auxiliaryWindows = [UIScreen: UIWindow]()

    private(set) var appScreen: UIScreen
    var displayScreen: UIScreen? {
        displayController.view.window?.windowScene?.screen
    }

    private(set) var isMirroring: Bool
    private let subscriptionManager: SubscriptionManager
    private let core: AppCore
    private let executor: CelestiaExecutor
    private let userDefaults: UserDefaults

    // On Mac, we have top title bar/toolbar, which covers
    // part of the view, we do not to extend to below the bars
    #if targetEnvironment(macCatalyst)
    private let safeAreaEdges: NSDirectionalRectEdge = {
        if #available(iOS 26, *) {
            return []
        }
        return .top
    }()
    #else
    private let safeAreaEdges: NSDirectionalRectEdge = {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return .top
        }
        return []
    }()
    #endif

    #if !targetEnvironment(macCatalyst)
    let gyroscopeSettings = GyroscopeSettings(isEnabled: false)
    private var gyroscopeSettingsSubscription: Set<AnyCancellable> = []
    #endif

    init(screen: UIScreen, executor: CelestiaExecutor, userDefaults: UserDefaults, subscriptionManager: SubscriptionManager, core: AppCore) {
        appScreen = screen
        isMirroring = false
        self.subscriptionManager = subscriptionManager
        self.core = core
        self.executor = executor
        self.userDefaults = userDefaults
        displayController = CelestiaDisplayController(msaaEnabled: userDefaults[.msaa] == true, screen: screen, initialFrameRate: userDefaults[.frameRate] ?? 60, executor: executor, subscriptionManager: subscriptionManager, core: core, userDefaults: userDefaults)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let container = UIView()
        container.backgroundColor = .systemBackground
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        displayController.delegate = self
        install(displayController, safeAreaEdges: safeAreaEdges)

        NotificationCenter.default.addObserver(self, selector: #selector(windowDidMoveToScreenNotification(_:)), name: NSNotification.Name("UIWindowDidMoveToScreenNotification"), object: nil)
        #if !targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(self, selector: #selector(windowSceneEnterForegroundNotification(_:)), name: screenEnterForegroundNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowSceneEnterBackgroundNotification(_:)), name: screenEnterBackgroundNotificationName, object: nil)
        #endif
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            guard let key = press.key else { continue }

            handled = true
            interactionController?.keyDown(with: key.input, modifiers: UInt(key.modifierFlags.rawValue))
        }

        if !handled {
            super.pressesBegan(presses, with: event)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            guard let key = press.key else { continue }

            handled = true
            interactionController?.keyUp(with: key.input, modifiers: UInt(key.modifierFlags.rawValue))
        }

        if !handled {
            super.pressesEnded(presses, with: event)
        }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            guard let key = press.key else { continue }

            handled = true
            interactionController?.keyUp(with: key.input, modifiers: UInt(key.modifierFlags.rawValue))
        }

        if !handled {
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
    }
}

#if !targetEnvironment(macCatalyst)
extension CelestiaViewController {
    @objc private func windowSceneEnterForegroundNotification(_ notification: Notification) {
        guard let windowScene = notification.object as? UIWindowScene else { return }
        if let window = auxiliaryWindows[windowScene.screen] {
            move(to: window, screen: window.screen)
        }
    }

    @objc private func windowSceneEnterBackgroundNotification(_ notification: Notification) {
        guard let windowScene = notification.object as? UIWindowScene else { return }
        if let window = auxiliaryWindows[windowScene.screen] {
            moveBack(from: window)
        }
    }
}
#endif

extension CelestiaViewController: CelestiaInteractionControllerDelegate {
    func celestiaInteractionControllerRequestShowActionMenu(_ celestiaInteractionController: CelestiaInteractionController) {
        delegate?.celestiaControllerRequestShowActionMenu(self)
    }

    func celestiaInteractionControllerRequestShowSearch(_ celestiaInteractionController: CelestiaInteractionController) {
        delegate?.celestiaControllerRequestShowSearch(self)
    }

    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestShowInfoWithSelection selection: Selection) {
        delegate?.celestiaController(self, requestShowInfoWithSelection: selection)
    }

    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestShowSubsystemWithSelection selection: Selection) {
        delegate?.celestiaController(self, requestShowSubsystemWithSelection: selection)
    }

    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestWebInfo webURL: URL) {
        delegate?.celestiaController(self, requestWebInfo: webURL)
    }

    func celestiaInteractionControllerCanAcceptKeyEvents(_ celestiaInteractionController: CelestiaInteractionController) -> Bool {
        return delegate?.celestiaControllerCanAcceptKeyEvents(self) ?? false
    }

    func celestiaInteractionControllerRequestGo(_ celestiaInteractionController: CelestiaInteractionController) {
        delegate?.celestiaControllerRequestGo(self)
    }
}

extension CelestiaViewController: CelestiaDisplayControllerDelegate {
    nonisolated func celestiaDisplayControllerLoadingSucceeded(_ celestiaDisplayController: CelestiaDisplayController) {
        Task.detached { @MainActor in
            let interactionController = CelestiaInteractionController(subscriptionManager: self.subscriptionManager, core: self.core, executor: self.executor, userDefaults: self.userDefaults)
            #if !targetEnvironment(macCatalyst)
            interactionController.setGyroscopeEnabled(self.gyroscopeSettings.isEnabled)
            #endif
            interactionController.delegate = self
            interactionController.targetProvider = self
            #if !targetEnvironment(macCatalyst)
            self.gyroscopeSettings.$isEnabled.sink { [weak self] isEnabled in
                guard let self else { return }
                self.interactionController?.setGyroscopeEnabled(isEnabled)
            }
            .store(in: &self.gyroscopeSettingsSubscription)
            #endif
            self.install(interactionController, safeAreaEdges: self.safeAreaEdges)
            self.interactionController = interactionController
            if self.isMirroring {
                interactionController.startMirroring()
            }
            self.delegate?.celestiaControllerLoadingSucceeded(self)
        }
    }

    nonisolated func celestiaDisplayControllerLoadingFailedShouldRetry(_ celestiaDisplayController: CelestiaDisplayController) -> Bool {
        final class RetryRequest: @unchecked Sendable {
            var shouldRetry: Bool = false
        }
        let request = RetryRequest()
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Task { @MainActor in
            self.delegate?.celestiaController(self, loadingFailedShouldRetry: { result in
                request.shouldRetry = result
                dispatchGroup.leave()
            })
        }
        dispatchGroup.wait()
        return request.shouldRetry
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
    func openURL(_ url: URL) {
        interactionController?.openURL(url)
    }

    func updateFrameRate(_ newFrameRate: Int) {
        displayController.setPreferredFramesPerSecond(newFrameRate)
    }

    #if !targetEnvironment(macCatalyst)
    private func move(to window: UIWindow, screen: UIScreen) {
        // Only move the display controller to the new screen
        displayController.remove()
        let dummyViewController = UIViewController()
        dummyViewController.view.backgroundColor = .black
        window.rootViewController = dummyViewController
        dummyViewController.install(displayController, safeAreaEdges: safeAreaEdges)
        interactionController?.startMirroring()
        isMirroring = true
    }

    private func moveBack(from window: UIWindow) {
        // Only move back when it has the display view controller
        guard let rootViewController = window.rootViewController, rootViewController.children.contains(displayController) else { return }
        displayController.remove()
        window.rootViewController = nil
        install(displayController, safeAreaEdges: safeAreaEdges)
        view.sendSubviewToBack(displayController.view)
        isMirroring = false
        interactionController?.stopMirroring()
    }

    func move(to windowScene: UIWindowScene) -> Bool {
        let newWindow = UIWindow(windowScene: windowScene)
        auxiliaryWindows[windowScene.screen] = newWindow
        move(to: newWindow, screen: windowScene.screen)
        if let sceneDelegate = windowScene.delegate as? ExternalScreenSceneDelegate {
            sceneDelegate.window = newWindow
        }
        newWindow.isHidden = false
        return true
    }

    func moveBack(from screen: UIScreen) -> Bool {
        guard let window = auxiliaryWindows.removeValue(forKey: screen) else {
            // No window with this screen is found
            return false
        }
        moveBack(from: window)
        return true
    }
    #endif
}

extension CelestiaViewController: RenderingTargetInformationProvider {
    var targetGeometry: RenderingTargetGeometry {
        return displayController.targetGeometry
    }

    var targetContents: Any? {
        return displayController.screenshot()
    }

    var targetView: UIView {
        return displayController.view
    }
}

private extension UIKey {
    var input: String? {
        let c = characters
        if c.count > 0 {
            return c
        }
        return charactersIgnoringModifiers
    }
}
