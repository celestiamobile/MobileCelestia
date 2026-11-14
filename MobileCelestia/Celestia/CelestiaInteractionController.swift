// CelestiaInteractionController.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaFoundation
import CelestiaUI
#if !targetEnvironment(macCatalyst)
import CoreMotion
import SwiftUI
import TipKit
import simd
#endif
import UIKit

@MainActor
protocol CelestiaInteractionControllerDelegate: AnyObject {
    func celestiaInteractionControllerRequestShowActionMenu(_ celestiaInteractionController: CelestiaInteractionController)
    func celestiaInteractionControllerRequestShowSearch(_ celestiaInteractionController: CelestiaInteractionController)
    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestShowInfoWithSelection selection: Selection)
    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestShowSubsystemWithSelection selection: Selection)
    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestWebInfo webURL: URL)
    func celestiaInteractionControllerRequestGo(_ celestiaInteractionController: CelestiaInteractionController)
    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, didUpdateControlToolbarItems toolbarItems: [UIBarButtonItem])
    func celestiaInteractionControllerCanAcceptKeyEvents(_ celestiaInteractionController: CelestiaInteractionController) -> Bool
}

@MainActor
protocol RenderingTargetInformationProvider: AnyObject {
    var targetGeometry: RenderingTargetGeometry { get }
    #if !targetEnvironment(macCatalyst)
    func startMirroring() -> UIView
    func stopMirroring()
    #endif
}

extension UIKeyModifierFlags: @unchecked @retroactive Sendable {}

class CelestiaInteractionController: UIViewController {
    private enum InteractionMode {
        case object
        case camera

        var button: MouseButton {
            return self == .object ? .right : .left
        }

        var next: InteractionMode {
            return self == .object ? .camera : .object
        }
    }

    private enum ZoomMode {
        case `in`
        case out

        var distance: CGFloat {
            return self == .out ? 1.5 : -1.5
        }
    }

    struct Constants {
        static let controlViewMarginTrailing: CGFloat = 8
        static let controlViewHideAnimationDuration: TimeInterval = 0.2
        static let controlViewShowAnimationDuration: TimeInterval = 0.2
    }

    #if targetEnvironment(macCatalyst)
    private var interactionMode: InteractionMode {
        return .camera
    }
    #else
    private var interactionMode: InteractionMode = .object
    #endif

    private var zoomMode: ZoomMode? = nil

    #if !targetEnvironment(macCatalyst)
    private lazy var controlViewActions: [QuickAction] = {
        if subscriptionManager.transactionInfo() != nil, let stringValue: String = userDefaults[UserDefaultsKey.toolbarItems] {
            var actions = QuickAction.from(stringValue) ?? QuickAction.defaultItems
            if !actions.contains(.menu) {
                actions.append(.menu)
            }
            return actions
        }
        return QuickAction.defaultItems
    }()
    private func controlViewImage(_ name: String, legacyName: String) -> UIImage? {
        if #available(iOS 26, *) {
            return UIImage(systemName: name)
        }
        return UIImage(systemName: legacyName)
    }
    private lazy var controlButtons = controlViewActions.map { action in
        switch action {
        case .mode:
            CelestiaControlButton.toggle(accessibilityLabel:  CelestiaString("Toggle Interaction Mode", comment: "Touch interaction mode"), offImage: UIImage(systemName: "cube"), offAction: .switchToObject, offAccessibilityValue: CelestiaString("Camera Mode", comment: "Interaction mode for touch"), onImage: UIImage(systemName: "video"), onAction: .switchToCamera, onAccessibilityValue: CelestiaString("Object Mode", comment: "Interaction mode for touch"))
        case .info:
            CelestiaControlButton.tap(image: controlViewImage("info", legacyName: "info.circle"), action: .info, accessibilityLabel: CelestiaString("Get Info", comment: "Action for getting info about current selected object"))
        case .search:
            CelestiaControlButton.tap(image: controlViewImage("magnifyingglass", legacyName: "magnifyingglass.circle"), action: .search, accessibilityLabel: CelestiaString("Search", comment: ""))
        case .menu:
            CelestiaControlButton.tap(image: controlViewImage("line.3.horizontal", legacyName: "line.3.horizontal.circle") ?? controlViewImage("line.horizontal.3", legacyName: "line.horizontal.3.circle"), action: .showMenu, accessibilityLabel: CelestiaString("Menu", comment: "Menu button"))
        case .hide:
            CelestiaControlButton.tap(image: controlViewImage("xmark", legacyName: "xmark.circle"), action: .hide, accessibilityLabel: CelestiaString("Hide", comment: "Action to hide the tool overlay"))
        case .zoomIn:
            CelestiaControlButton.pressAndHold(image: controlViewImage("plus.magnifyingglass", legacyName: "plus.circle"), action: .zoomIn, accessibilityLabel: CelestiaString("Zoom In", comment: ""))
        case .zoomOut:
            CelestiaControlButton.pressAndHold(image: controlViewImage("minus.magnifyingglass", legacyName: "minus.circle"), action: .zoomOut, accessibilityLabel: CelestiaString("Zoom Out", comment: ""))
        case .go:
            CelestiaControlButton.tap(image: controlViewImage("paperplane", legacyName: "paperplane.circle"), action: .go, accessibilityLabel: CelestiaString("Go", comment: "Go to an object"))
        }
    }
    private lazy var activeControlView = CelestiaControlView(items: controlButtons)
    private lazy var controlToolbarItems: [UIBarButtonItem] = {
        if #available(anyAppleOS 27.1, *) {
            return controlButtons.map { createControlToolbarItem(for: $0) }
        }
        return []
    }()
    private var controlButtonsByToolbarItem = [ObjectIdentifier: CelestiaControlButton]()
    #endif

    // MARK: gesture
    #if !targetEnvironment(macCatalyst)
    private lazy var showControlViewGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleShowControlView(_:)))
    private weak var controlViewRestoreHintView: UIView?
    private var controlViewRestoreHintTask: Task<Void, Never>?
    private weak var controlViewRestoreHintController: UIViewController?
    #endif
    private var currentPanPoint: CGPoint?
    #if targetEnvironment(macCatalyst)
    private var currentPanStartPoint: CGPoint?
    #endif
    private var currentPinchScale: CGFloat?

    private let core: AppCore
    private let executor: CelestiaExecutor
    private let userDefaults: UserDefaults
    private let subscriptionManager: SubscriptionManager

    weak var delegate: CelestiaInteractionControllerDelegate?
    weak var targetProvider: RenderingTargetInformationProvider?

    #if targetEnvironment(macCatalyst)
    private var zoomByDistance = false
    private lazy var hideCursorDuringDragging = userDefaults[.hideCursorDuringDragging] ?? true
    private lazy var infiniteDragging = hideCursorDuringDragging && (userDefaults[.infiniteDragging] ?? true)
    #endif

    private var zoomTimer: Timer?

    #if !targetEnvironment(macCatalyst)
    private var isObservingGyroscopeUpdates = false
    private lazy var motionManager: CMMotionManager = {
        let motionManager = CMMotionManager()
        if #available(iOS 27, *) {
            motionManager.deviceMotionBody = view
        }
        motionManager.deviceMotionUpdateInterval = 0.02
        return motionManager
    }()
    var lastRotationQuaternion: simd_quatf?
    #endif

    private var renderingTargetGeometry: RenderingTargetGeometry {
        return targetProvider?.targetGeometry ?? RenderingTargetGeometry(size: view.frame.size, scale: view.contentScaleFactor)
    }

    final class FocusableView: UIView {
        override var canBecomeFocused: Bool { return true }
        override var canBecomeFirstResponder: Bool { return true }
    }

    #if !targetEnvironment(macCatalyst)
    private var mirroringView: UIView?
    #endif
    private lazy var targetInteractionView: UIView = {
        let view = FocusableView()
        view.focusEffect = nil
        return view
    }()
    private lazy var auxillaryContextMenuPreviewView = UIView()

    private var isControlViewVisible = true
    private weak var currentShowAnimator: UIViewPropertyAnimator?
    private weak var currentHideAnimator: UIViewPropertyAnimator?

    private var gameControllerManager: GameControllerManager?

    init(subscriptionManager: SubscriptionManager, core: AppCore, executor: CelestiaExecutor, userDefaults: UserDefaults) {
        self.subscriptionManager = subscriptionManager
        self.core = core
        self.executor = executor
        self.userDefaults = userDefaults
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if !targetEnvironment(macCatalyst)
    isolated deinit {
        controlViewRestoreHintTask?.cancel()
    }
    #endif

    override func loadView() {
        let container = UIView()

        targetInteractionView.contentMode = .scaleToFill
        targetInteractionView.isUserInteractionEnabled = true
        targetInteractionView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(targetInteractionView)

        NSLayoutConstraint.activate([
            targetInteractionView.topAnchor.constraint(equalTo: container.topAnchor),
            targetInteractionView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            targetInteractionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            targetInteractionView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        #if !targetEnvironment(macCatalyst)
        activeControlView.delegate = self
        activeControlView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(activeControlView)

        NSLayoutConstraint.activate([
            activeControlView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            activeControlView.trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.controlViewMarginTrailing),
        ])

        #endif

        auxillaryContextMenuPreviewView.backgroundColor = .clear
        container.addSubview(auxillaryContextMenuPreviewView)
        auxillaryContextMenuPreviewView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)

        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpGestures()
        setUpGameControllerManager()

        core.delegate = self

        #if !targetEnvironment(macCatalyst)
        #if os(iOS)
        if #available(anyAppleOS 27.1, *) {
            registerForTraitChanges(UITraitCollection.systemTraitsAffectingVerticalBarEdge) { (self: Self, _) in
                self.updateControlPresentation()
            }
        }
        #endif
        updateControlPresentation()
        #endif
    }

    #if !targetEnvironment(macCatalyst)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        showControlViewGesture.edges = view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? .left : .right
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissControlViewRestoreHint()
    }
    #endif
}

#if !targetEnvironment(macCatalyst)
extension CelestiaInteractionController: CelestiaControlViewDelegate {
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, pressDidStartWith action: CelestiaControlAction) {
        startPressingControl(action)
    }

    func celestiaControlView(_ celestiaControlView: CelestiaControlView, pressDidEndWith action: CelestiaControlAction) {
        stopPressingControl()
    }

    func celestiaControlView(_ celestiaControlView: CelestiaControlView, didTapWith action: CelestiaControlAction) {
        performControlAction(action)
    }

    func celestiaControlView(_ celestiaControlView: CelestiaControlView, didToggleTo action: CelestiaControlAction) {
        toggleInteractionMode(to: action)
    }

    private func startPressingControl(_ action: CelestiaControlAction) {
        zoomMode = action == .zoomIn ? .in : .out
        zoomTimer?.invalidate()
        zoomTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(callZoom), userInfo: nil, repeats: true)
        callZoom()
    }

    private func stopPressingControl() {
        zoomMode = nil
        zoomTimer?.invalidate()
        zoomTimer = nil
    }

    private func performControlAction(_ action: CelestiaControlAction) {
        if action == .hide {
            guard isControlViewVisible else { return }
            hideControlView()
            showControlViewRestoreHintIfNeeded()
        } else if action == .show {
            showControlView()
        } else if action == .showMenu {
            delegate?.celestiaInteractionControllerRequestShowActionMenu(self)
        } else if action == .info {
            Task {
                let selection = await executor.selection
                self.delegate?.celestiaInteractionController(self, requestShowInfoWithSelection: selection)
            }
        } else if action == .search {
            delegate?.celestiaInteractionControllerRequestShowSearch(self)
        } else if action == .go {
            delegate?.celestiaInteractionControllerRequestGo(self)
        }
    }

    private func showControlViewRestoreHintIfNeeded() {
        guard !isControlViewVisible,
              userDefaults[.controlViewRestoreHintAcknowledged] != true,
              view.window != nil,
              presentedViewController == nil else { return }
        let text = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
            ? CelestiaString("Swipe inward from the left edge of the screen to show the toolbar.", comment: "Hint shown the first time the toolbar is hidden in a right-to-left layout")
            : CelestiaString("Swipe inward from the right edge of the screen to show the toolbar.", comment: "Hint shown the first time the toolbar is hidden in a left-to-right layout")
        if #available(iOS 17, *) {
            controlViewRestoreHintTask?.cancel()
            controlViewRestoreHintTask = Task { @MainActor [weak self] in
                while !Task.isCancelled {
                    guard let userDefaults = self?.userDefaults else { return }
                    let revision: Int = userDefaults[.controlViewRestoreTipRevision] ?? 0
                    let tip = ControlViewRestoreTip(text: text, revision: revision)
                    var didDisplay = false
                    var retryInvalidatedTip = false
                    for await shouldDisplay in tip.shouldDisplayUpdates {
                        guard !Task.isCancelled, let self,
                              !self.isControlViewVisible,
                              self.view.window != nil,
                              userDefaults[.controlViewRestoreHintAcknowledged] != true else { return }
                        if shouldDisplay {
                            if self.controlViewRestoreHintView == nil {
                                self.showControlViewRestoreTip(tip)
                                didDisplay = true
                            }
                        } else {
                            self.controlViewRestoreHintView?.removeFromSuperview()
                            self.controlViewRestoreHintView = nil
                        }
                        if case .invalidated = tip.status {
                            // TipKit persists X dismissal; a new identity allows the next reminder.
                            userDefaults[.controlViewRestoreTipRevision] = revision + 1
                            if didDisplay {
                                self.controlViewRestoreHintTask = nil
                                return
                            }
                            retryInvalidatedTip = true
                            break
                        }
                    }
                    guard retryInvalidatedTip else { return }
                }
            }
        } else {
            let alert = UIAlertController(
                title: CelestiaString("Show the toolbar", comment: "Title for the hidden toolbar hint"),
                message: text,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: CelestiaString("Got it", comment: "Dismiss the hidden toolbar hint"), style: .default) { [weak self] _ in
                self?.userDefaults[.controlViewRestoreHintAcknowledged] = true
            })
            controlViewRestoreHintController = alert
            present(alert, animated: true)
        }
    }

    @available(iOS 17, *)
    private func showControlViewRestoreTip(_ tip: ControlViewRestoreTip) {
        let hint = TipUIView(tip, arrowEdge: nil) { [weak self] _ in
            self?.userDefaults[.controlViewRestoreHintAcknowledged] = true
            tip.invalidate(reason: .actionPerformed)
            self?.dismissControlViewRestoreHint()
        }
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)
        controlViewRestoreHintView = hint
        let horizontalMargin = GlobalConstants.pageMediumMarginHorizontal
        let preferredWidth = hint.widthAnchor.constraint(equalToConstant: 320)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            hint.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            hint.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: horizontalMargin),
            hint.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -horizontalMargin),
            preferredWidth,
            hint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -GlobalConstants.pageMediumMarginVertical)
        ])
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func dismissControlViewRestoreHint() {
        controlViewRestoreHintTask?.cancel()
        controlViewRestoreHintTask = nil
        controlViewRestoreHintView?.removeFromSuperview()
        controlViewRestoreHintView = nil
        controlViewRestoreHintController?.dismiss(animated: true)
        controlViewRestoreHintController = nil
    }

    private var usesControlToolbar: Bool {
        #if os(iOS)
        if #available(anyAppleOS 27.1, *) {
            switch traitCollection.verticalBarEdge {
            case .leading, .trailing:
                return true
            default:
                return false
            }
        }
        #endif
        return false
    }

    private func updateControlPresentation() {
        let usesControlToolbar = usesControlToolbar
        activeControlView.isHidden = usesControlToolbar
        activeControlView.alpha = isControlViewVisible ? 1 : 0
        delegate?.celestiaInteractionController(
            self,
            didUpdateControlToolbarItems: usesControlToolbar && isControlViewVisible ? controlToolbarItems : []
        )
    }

    @available(anyAppleOS 27.1, *)
    private func createControlToolbarItem(for button: CelestiaControlButton) -> UIBarButtonItem {
        let title: String
        switch button {
        case let .pressAndHold(_, _, accessibilityLabel),
             let .tap(_, _, accessibilityLabel),
             let .toggle(accessibilityLabel, _, _, _, _, _, _):
            title = accessibilityLabel
        }

        let item: UIBarButtonItem
        switch button {
        case let .pressAndHold(image, action, _):
            item = TouchDownUpBarButtonItem(image: image, touchDown: { [weak self] in
                self?.startPressingControl(action)
            }, touchUp: { [weak self] _ in
                self?.stopPressingControl()
            })
            item.menuRepresentation = UIAction(title: title, image: image) { [weak self] _ in
                self?.startPressingControl(action)
                self?.stopPressingControl()
            }
        case let .tap(image, _, _):
            item = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(performControlToolbarItemAction(_:)))
        case let .toggle(_, offImage, _, offAccessibilityValue, onImage, _, onAccessibilityValue):
            item = UIBarButtonItem(image: offImage, style: .plain, target: self, action: #selector(performControlToolbarItemAction(_:)))
            updateToggleToolbarItem(
                item,
                offImage: offImage,
                offAccessibilityValue: offAccessibilityValue,
                onImage: onImage,
                onAccessibilityValue: onAccessibilityValue
            )
        }
        item.title = title
        item.accessibilityLabel = title
        controlButtonsByToolbarItem[ObjectIdentifier(item)] = button
        #if os(iOS)
        item.visibilityPriority = .low
        #endif
        return item
    }

    @available(anyAppleOS 27.1, *)
    @objc private func performControlToolbarItemAction(_ item: UIBarButtonItem) {
        guard let button = controlButtonsByToolbarItem[ObjectIdentifier(item)] else { return }
        switch button {
        case let .tap(_, action, _):
            performControlAction(action)
        case let .toggle(_, offImage, offAction, offAccessibilityValue, onImage, onAction, onAccessibilityValue):
            toggleInteractionMode(to: interactionMode == .object ? onAction : offAction)
            updateToggleToolbarItem(
                item,
                offImage: offImage,
                offAccessibilityValue: offAccessibilityValue,
                onImage: onImage,
                onAccessibilityValue: onAccessibilityValue
            )
        case .pressAndHold:
            break
        }
    }

    @available(anyAppleOS 27.1, *)
    private func updateToggleToolbarItem(
        _ item: UIBarButtonItem,
        offImage: UIImage?,
        offAccessibilityValue: String,
        onImage: UIImage?,
        onAccessibilityValue: String
    ) {
        let isOn = interactionMode == .camera
        item.image = isOn ? onImage : offImage
        item.accessibilityValue = isOn ? offAccessibilityValue : onAccessibilityValue
    }

    private func hideControlView() {
        isControlViewVisible = false
        if usesControlToolbar {
            updateControlPresentation()
            return
        }
        guard currentHideAnimator == nil else { return }
        currentShowAnimator?.stopAnimation(true)
        currentShowAnimator = nil

        let animator = UIViewPropertyAnimator(duration: Constants.controlViewHideAnimationDuration, curve: .linear) { [weak self] in
            self?.activeControlView.alpha = 0
        }

        currentHideAnimator = animator
        animator.addCompletion { [weak self, weak animator] _ in
            guard let self, let animator, self.currentHideAnimator === animator else { return }
            self.currentHideAnimator = nil
        }
        animator.startAnimation()
    }

    private func showControlView() {
        dismissControlViewRestoreHint()
        isControlViewVisible = true
        if usesControlToolbar {
            updateControlPresentation()
            return
        }
        guard currentShowAnimator == nil else { return }
        currentHideAnimator?.stopAnimation(true)
        currentHideAnimator = nil

        let animator = UIViewPropertyAnimator(duration: Constants.controlViewShowAnimationDuration, curve: .linear) { [weak self] in
            self?.activeControlView.alpha = 1
        }

        currentShowAnimator = animator
        animator.addCompletion { [weak self, weak animator] _ in
            guard let self, let animator, self.currentShowAnimator === animator else { return }
            self.currentShowAnimator = nil
        }
        animator.startAnimation()
    }

    private func showControlViewIfNeeded() {
        guard !isControlViewVisible else { return }
        showControlView()
    }

    private func hideControlViewIfNeeded() {
        guard isControlViewVisible else { return }
        hideControlView()
    }

    private func toggleInteractionMode(to action: CelestiaControlAction) {
        let toastDuration: TimeInterval = 1
        interactionMode = action == .switchToObject ? .object : .camera
        activeControlView.setToggleState(interactionMode == .camera)
        switch action {
        case .switchToObject:
            interactionMode = .object
            if let window = view.window {
                Toast.show(text: CelestiaString("Switched to object mode", comment: "Move/zoom on an object"), in: window, duration: toastDuration)
            }
        case .switchToCamera:
            interactionMode = .camera
            if let window = view.window {
                Toast.show(text: CelestiaString("Switched to camera mode", comment: "Move/zoom camera FOV"), in: window, duration: toastDuration)
            }
        default:
            fatalError("Unknown mode found: \(action)")
        }
    }
}
#endif

extension CelestiaInteractionController {
    private class PanGestureRecognizer: UIPanGestureRecognizer {
        var supportedMouseButtons: UIEvent.ButtonMask {
            get { return _supportedMouseButtons }
            set { _supportedMouseButtons = newValue }
        }

        private var _supportedMouseButtons: UIEvent.ButtonMask = .primary

        // HACK, support other buttons by override this private method in UIKit
        @objc private var _defaultAllowedMouseButtons: UIEvent.ButtonMask {
            return _supportedMouseButtons
        }
    }

    private func setUpGestures() {
        let pan1 = PanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan1.minimumNumberOfTouches = 1
        pan1.maximumNumberOfTouches = 1
        pan1.delegate = self
        pan1.supportedMouseButtons = [.primary, .secondary]
        targetInteractionView.addGestureRecognizer(pan1)

        let pan2 = UIPanGestureRecognizer(target: self, action: #selector(handlePanZoom(_:)))
        pan2.allowedScrollTypesMask = [.discrete, .continuous]
        pan2.delegate = self
        targetInteractionView.addGestureRecognizer(pan2)
        pan2.require(toFail: pan1)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        targetInteractionView.addGestureRecognizer(pinch)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.delegate = self
        targetInteractionView.addGestureRecognizer(tap)

        #if !targetEnvironment(macCatalyst)
        showControlViewGesture.edges = view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? .left : .right
        showControlViewGesture.delegate = self
        targetInteractionView.addGestureRecognizer(showControlViewGesture)
        pan1.require(toFail: showControlViewGesture)
        pan2.require(toFail: showControlViewGesture)
        pinch.require(toFail: showControlViewGesture)
        tap.require(toFail: showControlViewGesture)
        #endif

        #if targetEnvironment(macCatalyst)
        let isContextMenuEnabled = true
        #else
        let isContextMenuEnabled: Bool = userDefaults[UserDefaultsKey.contextMenu] ?? true
        #endif
        if isContextMenuEnabled {
            targetInteractionView.addInteraction(UIContextMenuInteraction(delegate: self))
        }

        if let clickGesture = targetInteractionView.gestureRecognizers?.filter({ String(cString: object_getClassName($0)) == "_UISecondaryClickDriverGestureRecognizer" }).first {
            clickGesture.require(toFail: pan1)
        }

        #if targetEnvironment(macCatalyst)
        zoomByDistance = userDefaults[.pinchZoom] == 1
        #endif
    }
}

extension CelestiaInteractionController {
    #if !targetEnvironment(macCatalyst)
    @objc private func handleShowControlView(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard gesture.state == .began else { return }
        showControlViewIfNeeded()
    }
    #endif

    @objc private func handlePanZoom(_ pan: UIPanGestureRecognizer) {
        let modifiers = pan.modifierFlags
        switch pan.state {
        case .changed:
            let delta = pan.translation(with: renderingTargetGeometry).y / 400
            executor.runAsynchronously { $0.mouseWheel(by: delta, modifiers: UInt(modifiers.rawValue)) }
        case .possible, .began, .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            break
        }
    }

    @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
        let location = pan.location(with: renderingTargetGeometry)
        let modifiers = pan.modifierFlags
        let button: MouseButton
        if pan.buttonMask.contains(.primary) {
            button = .left
        } else if pan.buttonMask.contains(.secondary) {
            button = .right
        } else {
            button = interactionMode.button
        }
        switch pan.state {
        case .possible:
            break
        case .began:
            #if targetEnvironment(macCatalyst)
            if infiniteDragging {
                currentPanStartPoint = MacBridge.currentMouseLocation
            }
            if hideCursorDuringDragging {
                NSCursor.hide()
            }
            #endif
            currentPanPoint = location
            executor.runAsynchronously { $0.mouseButtonDown(at: location, modifiers: UInt(modifiers.rawValue), with: button) }
        case .changed:
            let current = currentPanPoint!
            let offset = CGPoint(x: location.x - current.x, y: location.y - current.y)
            currentPanPoint = location
            #if targetEnvironment(macCatalyst)
            let baseModifier: UInt = 0
            #else
            let baseModifier: UInt = EventModifier.touch.rawValue
            #endif
            executor.runAsynchronously { $0.mouseMove(by: offset, modifiers: UInt(modifiers.rawValue) | baseModifier, with: button) }
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            #if targetEnvironment(macCatalyst)
            if let startLocation = currentPanStartPoint {
                CGWarpMouseCursorPosition(startLocation)
                currentPanStartPoint = nil
            }
            if hideCursorDuringDragging {
                NSCursor.unhide()
            }
            #endif
            executor.runAsynchronously { $0.mouseButtonUp(at: location, modifiers: UInt(modifiers.rawValue), with: button) }
            currentPanPoint = nil
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .possible:
            break
        case .began:
            currentPinchScale = gesture.scale
        case .changed:
            let scale = gesture.scale
            #if targetEnvironment(macCatalyst)
            let zoomFOV = !zoomByDistance
            #else
            let zoomFOV = interactionMode == .camera
            #endif
            if let currentPinchScale {
                let focus = gesture.location(with: renderingTargetGeometry)
                executor.runAsynchronously {
                    $0.pinchUpdate(focus, scale: scale / currentPinchScale, zoomFOV: zoomFOV)
                }
            }
            currentPinchScale = scale
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            currentPinchScale = nil
        }
    }

    @objc private func handleTap(_ tap: UITapGestureRecognizer) {
        switch tap.state {
        case .ended:
            let location = tap.location(with: renderingTargetGeometry)
            executor.runAsynchronously { core in
                core.mouseButtonDown(at: location, modifiers: 0, with: .left)
                core.mouseButtonUp(at: location, modifiers: 0, with: .left)
            }
        default:
            break
        }
    }

    private func zoom(deltaY: CGFloat, modifiers: UInt = 0, scrolling: Bool = false) {
        if scrolling || interactionMode == .object {
            executor.runAsynchronously { core in
                core.mouseWheel(by: core.enableReverseWheel ? -deltaY : deltaY, modifiers: modifiers)
            }
        } else {
            executor.runAsynchronously { $0.mouseMove(by: CGPoint(x: 0, y: deltaY), modifiers: UInt(UIKeyModifierFlags.shift.rawValue), with: .left) }
        }
    }
}

extension CelestiaInteractionController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        #if !targetEnvironment(macCatalyst)
        if gestureRecognizer === showControlViewGesture {
            return !isControlViewVisible
        }
        #endif
        var area = gestureRecognizer.view!.bounds.inset(by: gestureRecognizer.view!.safeAreaInsets)
        // reserve area
        area = area.insetBy(dx: 16, dy: 16)
        if !area.contains(gestureRecognizer.location(in: gestureRecognizer.view)) {
            return false
        }
        return true
    }
}

extension CelestiaInteractionController: UIContextMenuInteractionDelegate {
    private class ContextMenuHandler: NSObject, AppCoreContextMenuHandler, @unchecked Sendable {
        func celestiaAppCoreCursorDidRequestContextMenu(at location: CGPoint, with selection: Selection) {
            pendingSelection = selection
        }

        var pendingSelection: Selection?
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let location = interaction.location(with: renderingTargetGeometry)

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self else { return nil }
            return UIMenu(options: .displayInline, children: [contextMenuForLocation(location: location, interaction: interaction)])
        }
    }

    private func contextMenuForLocation(location: CGPoint, interaction: UIContextMenuInteraction) -> UIDeferredMenuElement {
        return UIDeferredMenuElement.uncached { [weak self, weak interaction] completion in
            guard let self else {
                completion([])
                interaction?.dismissMenu()
                return
            }
            Task {
                guard let selection = await self.executor.get({ core in
                    let handler = ContextMenuHandler()
                    core.contextMenuHandler = handler
                    core.mouseButtonDown(at: location, modifiers: 0, with: .right)
                    core.mouseButtonUp(at: location, modifiers: 0, with: .right)
                    core.contextMenuHandler = nil
                    return handler.pendingSelection
                }) else {
                    completion([])
                    interaction?.dismissMenu()
                    return
                }

                let referenceMarkStates: [String: Bool]
                if selection.body != nil {
                    let referenceMarks = ["body axes", "frame axes", "sun direction", "velocity vector", "planetographic grid", "terminator"]
                    referenceMarkStates = await self.executor.get { core in
                        Dictionary(uniqueKeysWithValues: referenceMarks.map { referenceMark in
                            (referenceMark, core.isReferenceMarkEnabled(referenceMark, for: selection))
                        })
                    }
                } else {
                    referenceMarkStates = [:]
                }

                completion(self.contextMenuForSelection(selection: selection, referenceMarkStates: referenceMarkStates))
            }
        }
    }

    private func contextMenuForSelection(selection: Selection, referenceMarkStates: [String: Bool]) -> [UIMenuElement] {
        let menuActions = CelestiaAction.allCases
        let menuActionTitles = menuActions.map(\.description)
        let titleAction = UIAction(title: core.simulation.universe.name(for: selection)) { _ in }
        titleAction.attributes = [.disabled]
        var actions: [UIMenuElement] = [titleAction]

        actions.append(UIMenu(options: .displayInline, children: [
            UIAction(title: CelestiaString("Get Info", comment: "Action for getting info about current selected object")) { [weak self] _ in
                guard let self else { return }
                self.delegate?.celestiaInteractionController(self, requestShowInfoWithSelection: selection)
            }
        ]))

        actions.append(UIMenu(options: .displayInline, children: [UIAction(title: CelestiaString("Select", comment: "Select an object"), handler: { _ in
            Task { @CelestiaActor in
                let core = CelestiaActor.appCore
                core.simulation.selection = selection
            }
        })] + menuActions.enumerated().map { index, action in
            return UIAction(title: menuActionTitles[index]) { _ in
                Task { @CelestiaActor in
                    let core = CelestiaActor.appCore
                    core.simulation.selection = selection
                    core.receive(action)
                }
            }
        }))

        if let entry = selection.object {
            let browserItem = BrowserItem(name: core.simulation.universe.name(for: selection), catEntry: entry, provider: core.simulation.universe)
            var remainingMenuItems = BrowserItem.maximumContextMenuBrowserItems
            actions.append(UIMenu(options: .displayInline, children: browserItem.createChildMenuItems(object: entry, remainingMenuItems: &remainingMenuItems, additionalItemCount: menuActions.count + 2, additionalItemsProvider: { selection in
                let actions = [UIAction(title: CelestiaString("Select", comment: "Select an object"), handler: { _ in
                    Task { @CelestiaActor in
                        let core = CelestiaActor.appCore
                        core.simulation.selection = selection
                    }
                })] + menuActions.enumerated().map { index, action in
                    return UIAction(title: menuActionTitles[index]) { _ in
                        Task { @CelestiaActor in
                            let core = CelestiaActor.appCore
                            core.simulation.selection = selection
                            core.receive(action)
                        }
                    }
                }
                return [
                    UIAction(title: CelestiaString("Get Info", comment: "Action for getting info about current selected object"), handler: { [weak self] _ in
                        guard let self else { return }
                        self.delegate?.celestiaInteractionController(self, requestShowInfoWithSelection: selection)
                    }),
                    UIMenu(options: .displayInline, children: actions)
                ]
            }) { [weak self] selection in
                guard let self else { return }
                self.delegate?.celestiaInteractionController(self, requestShowSubsystemWithSelection: selection)
            }))
        }

        if let alternativeSurfaces = selection.body?.alternateSurfaceNames, alternativeSurfaces.count > 0 {
            let defaultSurfaceItem = UIAction(title: CelestiaString("Default", comment: "")) { [weak self] _ in
                guard let self else { return }
                self.executor.runAsynchronously { $0.simulation.activeObserver.displayedSurface = "" }
            }
            let otherSurfaces = alternativeSurfaces.map { name -> UIAction in
                let action = UIAction(title: name) { [weak self] _ in
                    guard let self else { return }
                    self.executor.runAsynchronously { $0.simulation.activeObserver.displayedSurface = name }
                }
                return action
            }
            let menu = UIMenu(title: CelestiaString("Alternate Surfaces", comment: "Alternative textures to display"), children: [defaultSurfaceItem] + otherSurfaces)
            actions.append(menu)
        }

        if selection.body != nil {
            let referenceVectors = [
                (CelestiaString("Show Body Axes", comment: "Reference vector"), "body axes"),
                (CelestiaString("Show Frame Axes", comment: "Reference vector"), "frame axes"),
                (CelestiaString("Show Sun Direction", comment: "Reference vector"), "sun direction"),
                (CelestiaString("Show Velocity Vector", comment: "Reference vector"), "velocity vector"),
                (CelestiaString("Show Planetographic Grid", comment: "Reference vector"), "planetographic grid"),
                (CelestiaString("Show Terminator", comment: "Reference vector"), "terminator"),
            ]
            let referenceVectorActions = referenceVectors.map { title, key in
                let isEnabled = referenceMarkStates[key] ?? false
                return UIAction(title: title, state: isEnabled ? .on : .off) { _ in
                    Task { @CelestiaActor in
                        CelestiaActor.appCore.toggleReferenceMark(key, for: selection)
                    }
                }
            }
            actions.append(UIMenu(
                title: CelestiaString("Reference Vectors", comment: "Reference vectors for an object"),
                children: referenceVectorActions
            ))
        }

        let markerOptions = (0...MarkerRepresentation.crosshair.rawValue).map { MarkerRepresentation(rawValue: $0)?.localizedTitle ?? "" } + [CelestiaString("Unmark", comment: "Unmark an object")]
        let markerMenu = UIMenu(title: CelestiaString("Mark", comment: "Mark an object"), children: markerOptions.enumerated().map() { index, name -> UIAction in
            return UIAction(title: name) { [weak self] _ in
                guard let self else { return }
                if let marker = MarkerRepresentation(rawValue: UInt(index)) {
                    Task {
                        await self.executor.mark(selection, markerType: marker)
                    }
                } else {
                    self.executor.runAsynchronously { $0.simulation.universe.unmark(selection) }
                }
            }
        })
        actions.append(UIMenu(options: .displayInline, children: [markerMenu]))
        return actions
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, highlightPreviewForItemWithIdentifier identifier: NSCopying) -> UITargetedPreview? {
        contextMenuHighlightPreview(for: interaction)
    }

    private func contextMenuHighlightPreview(for interaction: UIContextMenuInteraction) -> UITargetedPreview {
        let loc = interaction.location(in: view)
        auxillaryContextMenuPreviewView.frame = CGRect(origin: loc, size: CGSize(width: 1, height: 1))
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = UIColor.clear
        return UITargetedPreview(view: auxillaryContextMenuPreviewView, parameters: parameters)
    }
}

extension UIContextMenuInteraction {
    func location(with targetGeometry: RenderingTargetGeometry) -> CGPoint {
        let viewLoc = location(in: view)
        let viewSize = view?.frame.size ?? targetGeometry.size
        let normalized = CGPoint(x: viewLoc.x / viewSize.width, y: viewLoc.y / viewSize.height)
        return CGPoint(x: normalized.x * targetGeometry.size.width, y: normalized.y * targetGeometry.size.height).scale(by: targetGeometry.scale)
    }
}

extension BrowserItem {
    fileprivate static let maximumContextMenuDepth = 2
    fileprivate static let maximumContextMenuBrowserItems = 100

    @MainActor
    private func createMenuItems(object: AstroObject, depth: Int, remainingMenuItems: inout Int, additionalItemCount: Int, additionalItemsProvider: (Selection) -> [UIMenuElement]?, showMoreHandler: @escaping (Selection) -> Void) -> UIMenu? {
        var items = [UIMenuElement]()
        var parent = object
        if let entry {
            parent = entry
            let selection = Selection(object: entry)
            if !selection.isEmpty, let additionalItems = additionalItemsProvider(selection) {
                items.append(contentsOf: additionalItems)
            }
        }

        let childItems = createChildMenuItems(object: parent, depth: depth, remainingMenuItems: &remainingMenuItems, additionalItemCount: additionalItemCount, additionalItemsProvider: additionalItemsProvider, showMoreHandler: showMoreHandler)
        if !childItems.isEmpty {
            items.append(UIMenu(options: .displayInline, children: childItems))
        }
        return items.isEmpty ? nil : UIMenu(title: name, children: items)
    }

    @MainActor
    func createChildMenuItems(object: AstroObject, depth: Int = 0, remainingMenuItems: inout Int, additionalItemCount: Int, additionalItemsProvider: (Selection) -> [UIMenuElement]?, showMoreHandler: @escaping (Selection) -> Void) -> [UIMenuElement] {
        let children = self.children
        guard !children.isEmpty else { return [] }

        // Reserve a fallback entry before descendants consume the shared budget.
        remainingMenuItems -= 1
        var items = [UIMenuElement]()
        var shouldInsertShowMore = depth >= Self.maximumContextMenuDepth
        if !shouldInsertShowMore {
            for child in children {
                let itemCost = child.entry == nil ? 1 : additionalItemCount + 1
                guard remainingMenuItems >= itemCost + 1 else {
                    shouldInsertShowMore = true
                    break
                }
                remainingMenuItems -= itemCost
                if let childMenu = child.createMenuItems(object: object, depth: depth + 1, remainingMenuItems: &remainingMenuItems, additionalItemCount: additionalItemCount, additionalItemsProvider: additionalItemsProvider, showMoreHandler: showMoreHandler) {
                    items.append(childMenu)
                } else {
                    remainingMenuItems += itemCost
                }
            }
        }
        if shouldInsertShowMore {
            items.append(UIMenu(options: .displayInline, children: [
                UIAction(title: CelestiaString("Show More…", comment: "Menu action to indicate that more items that are not shown in the menu"), handler: { _ in
                    let selection = Selection(object: object)
                    guard !selection.isEmpty else { return }
                    showMoreHandler(selection)
                })
            ]))
        } else {
            remainingMenuItems += 1
        }
        return items
    }
}

extension UIGestureRecognizer {
    func location(with targetGeometry: RenderingTargetGeometry) -> CGPoint {
        let viewLoc = location(in: view)
        let viewSize = view?.frame.size ?? targetGeometry.size
        let normalized = CGPoint(x: viewLoc.x / viewSize.width, y: viewLoc.y / viewSize.height)
        return CGPoint(x: normalized.x * targetGeometry.size.width, y: normalized.y * targetGeometry.size.height).scale(by: targetGeometry.scale)
    }

    func location(ofTouch touchIndex: Int, with targetGeometry: RenderingTargetGeometry) -> CGPoint {
        let viewLoc = location(ofTouch: touchIndex, in: view)
        let viewSize = view?.frame.size ?? targetGeometry.size
        let normalized = CGPoint(x: viewLoc.x / viewSize.width, y: viewLoc.y / viewSize.height)
        return CGPoint(x: normalized.x * targetGeometry.size.width, y: normalized.y * targetGeometry.size.height).scale(by: targetGeometry.scale)
    }
}
extension UIPanGestureRecognizer {
    func translation(with targetGeometry: RenderingTargetGeometry) -> CGPoint {
        let viewLoc = translation(in: view)
        let viewSize = view?.frame.size ?? targetGeometry.size
        let normalized = CGPoint(x: viewLoc.x / viewSize.width, y: viewLoc.y / viewSize.height)
        return CGPoint(x: normalized.x * targetGeometry.size.width, y: normalized.y * targetGeometry.size.height).scale(by: targetGeometry.scale)
    }
}

extension CelestiaInteractionController: AppCoreDelegate {
    nonisolated func celestiaAppCoreFatalErrorHappened(_ error: String) {
        Task { @MainActor in
            self.showError(CelestiaString("Fatal Error", comment: "Error for fatal error alert title"), detail: error)
        }
    }
    nonisolated func celestiaAppCoreRequestSystemAccess() -> Bool {
        class SystemAccessRequestResult: @unchecked Sendable {
            var granted: Bool

            init(granted: Bool) {
                self.granted = granted
            }
        }

        let result = SystemAccessRequestResult(granted: false)
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Task { @MainActor in
            self.showOption(
                CelestiaString("Script System Access", comment: "Alert title for scripts requesting system access"),
                message: CelestiaString("This script requests permission to read/write files and execute external programs. Allowing this can be dangerous.\nDo you trust the script and want to allow this?", comment: "Alert message for scripts requesting system access")
            ) { granted in
                result.granted = granted
                dispatchGroup.leave()
            }
        }
        dispatchGroup.wait()
        return result.granted
    }
    nonisolated func celestiaAppCoreCursorShapeChanged(_ shape: CursorShape) {}
    nonisolated func celestiaAppCoreWatchedFlagsDidChange(_ changedFlags: WatcherFlags) {}
}

#if !targetEnvironment(macCatalyst)
extension CelestiaInteractionController {
    func startMirroring() {
        guard mirroringView == nil, let targetProvider else { return }

        loadViewIfNeeded()
        let mirroringView = targetProvider.startMirroring()
        mirroringView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(mirroringView, belowSubview: targetInteractionView)
        NSLayoutConstraint.activate([
            mirroringView.topAnchor.constraint(equalTo: view.topAnchor),
            mirroringView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mirroringView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mirroringView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        self.mirroringView = mirroringView
    }

    func stopMirroring() {
        guard let mirroringView else { return }
        targetProvider?.stopMirroring()
        mirroringView.removeFromSuperview()
        self.mirroringView = nil
    }
}
#endif

extension CelestiaInteractionController {
    @objc private func callZoom() {
        if let mode = zoomMode {
            zoom(deltaY: mode.distance)
        }
    }

    func keyDown(with input: String?, modifiers: UInt) {
        guard delegate?.celestiaInteractionControllerCanAcceptKeyEvents(self) == true else {
            return
        }

        executor.runAsynchronously { $0.keyDown(with: input, modifiers: modifiers) }
    }

    func keyUp(with input: String?, modifiers: UInt) {
        guard delegate?.celestiaInteractionControllerCanAcceptKeyEvents(self) == true else {
            return
        }

        executor.runAsynchronously { $0.keyUp(with: input, modifiers: modifiers) }
    }

    func openURL(_ url: URL) {
        if url.isFileURL {
            executor.runAsynchronously { $0.runScript(at: url.path) }
        } else {
            executor.runAsynchronously { $0.go(to: url.absoluteString) }
        }
    }
}

private extension CelestiaInteractionController {
    private func setUpGameControllerManager() {
        gameControllerManager = GameControllerManager(
            executor: executor,
            canAcceptEvents: { [weak self] in
                guard let self else { return false }
                return self.delegate?.celestiaInteractionControllerCanAcceptKeyEvents(self) ?? false
            },
            actionRemapper: { [weak self] button in
                guard let self else { return nil }
                guard let remapped: Int = self.userDefaults[button.userDefaultsKey] else { return nil }
                return GameControllerAction(rawValue: remapped)
            },
            thumbstickStatus: { [weak self] thumbstick in
                guard let self else { return true }
                switch thumbstick {
                case .left:
                    return self.userDefaults[.gameControllerLeftThumbstickEnabled] != false
                case .right:
                    return self.userDefaults[.gameControllerRightThumbstickEnabled] != false
                }
            },
            axisInversion: { [weak self] axis in
                guard let self else { return false }
                switch axis {
                case .X:
                    return self.userDefaults[.gameControllerInvertX] == true
                case .Y:
                    return self.userDefaults[.gameControllerInvertY] == true
                }
            },
            menuButtonHandler: { [weak self] in
                guard let self else { return }
                self.delegate?.celestiaInteractionControllerRequestShowActionMenu(self)
            }
        )
    }
}

#if !targetEnvironment(macCatalyst)
extension CelestiaInteractionController {
    func setGyroscopeEnabled(_ enabled: Bool) {
        if enabled {
            guard motionManager.isDeviceMotionAvailable else { return }
            if !isObservingGyroscopeUpdates {
                motionManager.startDeviceMotionUpdates(to: .main) { [weak self] deviceMotionData, error in
                    guard let self, self.isObservingGyroscopeUpdates, let deviceMotionData, error == nil else { return }

                    let baseQuat = simd_quatf(deviceMotionData.attitude.quaternion)
                    let currentQuat: simd_quatf
                    if #available(iOS 27, *) {
                        currentQuat = baseQuat
                    } else {
                        let deviceOrientation = self.view.window?.windowScene?.interfaceOrientation ?? .portrait
                        switch deviceOrientation {
                        case .portraitUpsideDown:
                            currentQuat = simd_quatf(angle: .pi, axis: simd_float3(0, 0, 1)) * baseQuat
                        case .landscapeLeft:
                            currentQuat = simd_quatf(angle: -.pi / 2, axis: simd_float3(0, 0, 1)) * baseQuat
                        case .landscapeRight:
                            currentQuat = simd_quatf(angle: .pi / 2, axis: simd_float3(0, 0, 1)) * baseQuat
                        case .unknown, .portrait:
                            fallthrough
                        @unknown default:
                            currentQuat = baseQuat
                        }
                    }

                    guard let previousQuat = self.lastRotationQuaternion else {
                        self.lastRotationQuaternion = currentQuat
                        return
                    }
                    let relative = simd_normalize(currentQuat * simd_inverse(previousQuat))
                    self.lastRotationQuaternion = currentQuat
                    self.executor.runAsynchronously { core in
                        core.simulation.observerQuaternion = relative * core.simulation.observerQuaternion
                    }
                }
                isObservingGyroscopeUpdates = true
            }
        } else {
            if isObservingGyroscopeUpdates {
                motionManager.stopDeviceMotionUpdates()
                lastRotationQuaternion = nil
                isObservingGyroscopeUpdates = false
            }
        }
    }
}

private extension simd_quatf {
    init(_ quaternion: CMQuaternion) {
        self.init(ix: Float(quaternion.x), iy: Float(quaternion.y), iz: Float(quaternion.z), r: -Float(quaternion.w))
    }
}
#endif

#if !targetEnvironment(macCatalyst)
@available(iOS 17, *)
private struct ControlViewRestoreTip: Tip {
    let text: String
    let revision: Int

    var id: String {
        "ControlViewRestoreTip-\(revision)"
    }

    var title: Text {
        Text(CelestiaString("Show the toolbar", comment: "Title for the hidden toolbar hint"))
    }

    var message: Text? {
        Text(text)
    }

    var actions: [Action] {
        Action(id: "dismiss", title: CelestiaString("Got it", comment: "Dismiss the hidden toolbar hint"))
    }
}
#endif

private extension CGPoint {
    func scale(by factor: CGFloat) -> CGPoint {
        return applying(CGAffineTransform(scaleX: factor, y: factor))
    }
}
