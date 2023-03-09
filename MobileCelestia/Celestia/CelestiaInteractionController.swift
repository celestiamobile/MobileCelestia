//
// CelestiaInteractionController.swift
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
import GameController

enum CelestiaAction: Int8 {
    case goTo = 103
    case goToSurface = 7
    case center = 99
    case playpause = 32
    case reverse = 106
    case slower = 107
    case faster = 108
    case currentTime = 33
    case syncOrbit = 121
    case lock = 58
    case chase = 34
    case follow = 102
    case runDemo = 100
    case cancelScript = 27
    case home = 104
    case track = 116
    case stop = 115
    case reverseSpeed = 113
}

enum CelestiaContinuousAction: Int {
    case travelFaster = 97
    case travelSlower = 122
    case f1 = 11
    case f2 = 12
    case f3 = 13
    case f4 = 14
    case f5 = 15
    case f6 = 16
    case f7 = 17
}

extension CelestiaAction {
    static var allCases: [CelestiaAction] {
        return [.goTo, .center, .follow, .chase, .track, .syncOrbit, .lock, .goToSurface]
    }
}

@MainActor
protocol CelestiaInteractionControllerDelegate: AnyObject {
    func celestiaInteractionControllerRequestShowActionMenu(_ celestiaInteractionController: CelestiaInteractionController)
    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestShowInfoWithSelection selection: Selection)
    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestWebInfo webURL: URL)
    func celestiaInteractionControllerCanAcceptKeyEvents(_ celestiaInteractionController: CelestiaInteractionController) -> Bool
}

@MainActor
protocol RenderingTargetInformationProvider: AnyObject {
    var targetGeometry: RenderingTargetGeometry { get }
    var targetContents: Any? { get }
}

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

    #if targetEnvironment(macCatalyst)
    private lazy var activeControlView = CelestiaControlView(items: [
        CelestiaControlButton.tap(image: UIImage(systemName: "info.circle"), action: .info, accessibilityLabel: CelestiaString("Get Info", comment: "")),
        CelestiaControlButton.tap(image: UIImage(systemName: "line.3.horizontal.circle") ?? UIImage(systemName: "line.horizontal.3.circle") ?? UIImage(named: "control_action_menu"), action: .showMenu, accessibilityLabel: CelestiaString("Menu", comment: "")),
        CelestiaControlButton.tap(image: UIImage(systemName: "xmark.circle"), action: .hide, accessibilityLabel: CelestiaString("Hide", comment: "")),
    ])
    #else
    private lazy var activeControlView = CelestiaControlView(items: [
        CelestiaControlButton.toggle(accessibilityLabel:  CelestiaString("Toggle Interaction Mode", comment: ""), offImage: UIImage(systemName: "cube"), offAction: .switchToObject, offAccessibilityValue: CelestiaString("Camera Mode", comment: ""), onImage: UIImage(systemName: "video"), onAction: .switchToCamera, onAccessibilityValue: CelestiaString("Object Mode", comment: "")),
        CelestiaControlButton.pressAndHold(image: UIImage(systemName: "plus.circle"), action: .zoomIn, accessibilityLabel: CelestiaString("Zoom In", comment: "")),
        CelestiaControlButton.pressAndHold(image: UIImage(systemName: "minus.circle"), action: .zoomOut, accessibilityLabel: CelestiaString("Zoom Out", comment: "")),
        CelestiaControlButton.tap(image: UIImage(systemName: "info.circle"), action: .info, accessibilityLabel: CelestiaString("Get Info", comment: "")),
        CelestiaControlButton.tap(image: UIImage(systemName: "line.3.horizontal.circle") ?? UIImage(systemName: "line.horizontal.3.circle") ?? UIImage(named: "control_action_menu"), action: .showMenu, accessibilityLabel: CelestiaString("Menu", comment: "")),
        CelestiaControlButton.tap(image: UIImage(systemName: "xmark.circle"), action: .hide, accessibilityLabel: CelestiaString("Hide", comment: "")),
    ])
    #endif

    private var currentControlView: CelestiaControlView?

    // MARK: gesture
    private var currentPanPoint: CGPoint?
    #if targetEnvironment(macCatalyst)
    private var currentPanStartPoint: CGPoint?
    #endif
    private var currentPinchDistance: CGFloat?

    @Injected(\.appCore) private var core
    @Injected(\.executor) private var executor
    @Injected(\.userDefaults) private var userDefaults

    weak var delegate: CelestiaInteractionControllerDelegate?
    weak var targetProvider: RenderingTargetInformationProvider?

    private var zoomTimer: Timer?

    private var renderingTargetGeometry: RenderingTargetGeometry {
        return targetProvider?.targetGeometry ?? RenderingTargetGeometry(size: view.frame.size, scale: view.contentScaleFactor)
    }

    private var renderingTargetContents: Any? {
        return targetProvider?.targetContents
    }

    @available(iOS 15, *)
    final class FocusableView: UIView {
        override var canBecomeFocused: Bool { return true }
        override var canBecomeFirstResponder: Bool { return true }
    }

    private lazy var targetInteractionView: UIView = {
        if #available(iOS 15, *) {
            let view = FocusableView()
            view.focusEffect = nil
            return view
        }
        return UIView()
    }()
    private lazy var auxillaryContextMenuPreviewView = UIView()
    private var mirroringDisplayLink: CADisplayLink?
    private var isMirroring = false

    private var isControlViewVisible = true
    private weak var currentShowAnimator: UIViewPropertyAnimator?
    private weak var currentHideAnimator: UIViewPropertyAnimator?

    private var connectedGameController: GCController?

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

        activeControlView.delegate = self
        activeControlView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(activeControlView)

        NSLayoutConstraint.activate([
            activeControlView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            activeControlView.trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.controlViewMarginTrailing),
        ])

        currentControlView = activeControlView

        auxillaryContextMenuPreviewView.backgroundColor = .clear
        container.addSubview(auxillaryContextMenuPreviewView)
        auxillaryContextMenuPreviewView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)

        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupGestures()
        startObservingGameControllerConnection()

        core.delegate = self
    }
}

extension CelestiaInteractionController: CelestiaControlViewDelegate {
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, pressDidStartWith action: CelestiaControlAction) {
        zoomMode = action == .zoomIn ? .in : .out
        zoomTimer?.invalidate()
        zoomTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(callZoom), userInfo: nil, repeats: true)
        callZoom()
    }

    func celestiaControlView(_ celestiaControlView: CelestiaControlView, pressDidEndWith action: CelestiaControlAction) {
        zoomMode = nil
        zoomTimer?.invalidate()
        zoomTimer = nil
    }

    func celestiaControlView(_ celestiaControlView: CelestiaControlView, didTapWith action: CelestiaControlAction) {
        if action == .hide {
            self.hideControlView()
        } else if action == .show {
            self.showControlView()
        } else if action == .showMenu {
            self.delegate?.celestiaInteractionControllerRequestShowActionMenu(self)
        } else if action == .info {
            Task {
                let selection = await executor.selection
                self.delegate?.celestiaInteractionController(self, requestShowInfoWithSelection: selection)
            }
        }
    }

    private func hideControlView() {
        guard currentHideAnimator == nil else { return }
        currentShowAnimator?.stopAnimation(true)
        currentShowAnimator?.finishAnimation(at: .current)
        currentShowAnimator = nil

        let animator = UIViewPropertyAnimator(duration: Constants.controlViewHideAnimationDuration, curve: .linear) { [weak self] in
            self?.activeControlView.alpha = 0
        }

        animator.addCompletion { [weak self] _ in
            self?.currentHideAnimator = nil
            self?.isControlViewVisible = false
        }

        currentHideAnimator = animator
        animator.startAnimation()
    }

    private func showControlView() {
        guard currentShowAnimator == nil else { return }
        currentHideAnimator?.stopAnimation(true)
        currentHideAnimator?.finishAnimation(at: .current)
        currentHideAnimator = nil

        let animator = UIViewPropertyAnimator(duration: Constants.controlViewShowAnimationDuration, curve: .linear) { [weak self] in
            self?.activeControlView.alpha = 1
        }

        animator.addCompletion { [weak self] _ in
            self?.currentShowAnimator = nil
            self?.isControlViewVisible = true
        }

        currentShowAnimator = animator
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

    func celestiaControlView(_ celestiaControlView: CelestiaControlView, didToggleTo action: CelestiaControlAction) {
        #if !targetEnvironment(macCatalyst)
        let toastDuration: TimeInterval = 1
        interactionMode = action == .switchToObject ? .object : .camera
        switch action {
        case .switchToObject:
            interactionMode = .object
            if let window = view.window {
                Toast.show(text: CelestiaString("Switched to object mode", comment: ""), in: window, duration: toastDuration)
            }
        case .switchToCamera:
            interactionMode = .camera
            if let window = view.window {
                Toast.show(text: CelestiaString("Switched to camera mode", comment: ""), in: window, duration: toastDuration)
            }
        default:
            fatalError("Unknown mode found: \(action)")
        }
        #endif
    }
}

extension CelestiaInteractionController {
    private class PanGestureRecognizer: UIPanGestureRecognizer {
        @available(iOS 13.4, *)
        var supportedMouseButtons: UIEvent.ButtonMask {
            get { return UIEvent.ButtonMask(rawValue: supportedMouseButtonsRawValue) }
            set { supportedMouseButtonsRawValue = newValue.rawValue }
        }

        private var supportedMouseButtonsRawValue: Int = {
            if #available(iOS 13.4, *) {
                return UIEvent.ButtonMask.primary.rawValue
            }
            return 1
        }()

        // HACK, support other buttons by override this private method in UIKit
        @objc private var _defaultAllowedMouseButtons: Int {
            return supportedMouseButtonsRawValue
        }
    }

    private func setupGestures() {
        let pan1 = PanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan1.minimumNumberOfTouches = 1
        pan1.maximumNumberOfTouches = 1
        pan1.delegate = self
        if #available(iOS 13.4, *) {
            pan1.supportedMouseButtons = [.primary, .secondary]
        }
        targetInteractionView.addGestureRecognizer(pan1)

        if #available(iOS 13.4, *) {
            let pan2 = UIPanGestureRecognizer(target: self, action: #selector(handlePanZoom(_:)))
            pan2.allowedScrollTypesMask = [.discrete, .continuous]
            pan2.delegate = self
            targetInteractionView.addGestureRecognizer(pan2)
            pan2.require(toFail: pan1)
        }

        #if !targetEnvironment(macCatalyst)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        targetInteractionView.addGestureRecognizer(pinch)
        #endif

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.delegate = self
        targetInteractionView.addGestureRecognizer(tap)

        if #available(iOS 13.0, *) {
            targetInteractionView.addInteraction(UIContextMenuInteraction(delegate: self))
        }

        if let clickGesture = targetInteractionView.gestureRecognizers?.filter({ String(cString: object_getClassName($0)) == "_UISecondaryClickDriverGestureRecognizer" }).first {
            clickGesture.require(toFail: pan1)
        }
    }
}

extension CelestiaInteractionController {
    @objc private func handlePanZoom(_ pan: UIPanGestureRecognizer) {
        showControlViewIfNeeded()

        var modifiers: UIKeyModifierFlags = []
        if #available(iOS 13.4, *) {
            modifiers = pan.modifierFlags
        }
        switch pan.state {
        case .changed:
            zoom(deltaY: pan.translation(with: renderingTargetGeometry).y / 400, modifiers: UInt(modifiers.rawValue), scrolling: true)
        case .possible, .began, .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            break
        }
    }

    @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
        showControlViewIfNeeded()

        let location = pan.location(with: renderingTargetGeometry)
        var modifiers: UIKeyModifierFlags = []
        var button = interactionMode.button
        if #available(iOS 13.4, *) {
            modifiers = pan.modifierFlags
            if pan.buttonMask.contains(.secondary) {
                button = .right
            } else if pan.buttonMask.contains(.primary) {
                button = modifiers.contains(.alternate) ? .right : .left
            }
        }
        switch pan.state {
        case .possible:
            break
        case .began:
            #if targetEnvironment(macCatalyst)
            currentPanStartPoint = MacBridge.currentMouseLocation
            NSCursor.hide()
            #endif
            currentPanPoint = location
            executor.run { $0.mouseButtonDown(at: location, modifiers: UInt(modifiers.rawValue), with: button) }
        case .changed:
            let current = currentPanPoint!
            let offset = CGPoint(x: location.x - current.x, y: location.y - current.y)
            currentPanPoint = location
            executor.run { $0.mouseMove(by: offset, modifiers: UInt(modifiers.rawValue), with: button) }
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            #if targetEnvironment(macCatalyst)
            if let startLocation = currentPanStartPoint {
                CGWarpMouseCursorPosition(startLocation)
                currentPanStartPoint = nil
            }
            NSCursor.unhide()
            #endif
            executor.run { $0.mouseButtonUp(at: location, modifiers: UInt(modifiers.rawValue), with: button) }
            currentPanPoint = nil
        }
    }

    #if !targetEnvironment(macCatalyst)
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        showControlViewIfNeeded()

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
            let point1 = gesture.location(ofTouch: 0, with: renderingTargetGeometry)
            let point2 = gesture.location(ofTouch: 1, with: renderingTargetGeometry)
            let length = hypot(abs(point1.x - point2.x), abs(point1.y - point2.y))
            let center = CGPoint(x: (point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)
            currentPinchDistance = length
            executor.run { $0.mouseButtonDown(at: center, modifiers: 0, with: .left) }
        case .changed:
            if gesture.numberOfTouches < 2 {
                // cancel the gesture recognizer
                gesture.isEnabled = false
                gesture.isEnabled = true
                break
            }
            let point1 = gesture.location(ofTouch: 0, with: renderingTargetGeometry)
            let point2 = gesture.location(ofTouch: 1, with: renderingTargetGeometry)
            let length = hypot(abs(point1.x - point2.x), abs(point1.y - point2.y))
            let delta = length / currentPinchDistance!
            // FIXME: 8 is a magic number
            let y = (1 - delta) * currentPinchDistance! / 8
            zoom(deltaY: y)
            currentPinchDistance = length
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            currentPinchDistance = nil
        }
    }
    #endif

    @objc private func handleTap(_ tap: UITapGestureRecognizer) {
        showControlViewIfNeeded()

        switch tap.state {
        case .ended:
            let location = tap.location(with: renderingTargetGeometry)
            executor.run { core in
                core.mouseButtonDown(at: location, modifiers: 0, with: .left)
                core.mouseButtonUp(at: location, modifiers: 0, with: .left)
            }
        default:
            break
        }
    }

    private func zoom(deltaY: CGFloat, modifiers: UInt = 0, scrolling: Bool = false) {
        if scrolling || interactionMode == .object {
            executor.run { $0.mouseWheel(by: deltaY, modifiers: modifiers) }
        } else {
            executor.run { $0.mouseMove(by: CGPoint(x: 0, y: deltaY), modifiers: UInt(UIKeyModifierFlags.shift.rawValue), with: .left) }
        }
    }
}

extension CelestiaInteractionController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var area = gestureRecognizer.view!.bounds.inset(by: gestureRecognizer.view!.safeAreaInsets)
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

@available(iOS 13.0, *)
extension CelestiaInteractionController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let location = interaction.location(with: renderingTargetGeometry)

        class ContextMenuHandler: NSObject, AppCoreContextMenuHandler, @unchecked Sendable {
            func celestiaAppCoreCursorDidRequestContextMenu(at location: CGPoint, with selection: Selection) {
                pendingSelection = selection
            }

            var pendingSelection: Selection?
        }

        let handler = ContextMenuHandler()
        let selection = executor.get { core in
            core.contextMenuHandler = handler
            core.mouseButtonDown(at: location, modifiers: 0, with: .right)
            core.mouseButtonUp(at: location, modifiers: 0, with: .right)
            core.contextMenuHandler = nil
            return handler.pendingSelection
        }

        guard let selection else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ -> UIMenu? in
            guard let self = self else { return nil }
            let titleAction = UIAction(title: self.core.simulation.universe.name(for: selection)) { _ in }
            titleAction.attributes = [.disabled]
            var actions: [UIMenuElement] = [titleAction]

            actions.append(UIMenu(title: "", options: .displayInline, children: CelestiaAction.allCases.map { action in
                return UIAction(title: action.description) { _ in
                    Task {
                        await self.executor.selectAndReceive(selection, action: action)
                    }
                }
            }))

            if let entry = selection.object {
                let browserItem = BrowserItem(name: self.core.simulation.universe.name(for: selection), catEntry: entry, provider: self.core.simulation.universe)
                actions.append(UIMenu(title: "", options: .displayInline, children: browserItem.children.compactMap { $0.createMenuItems(additionalItemName: CelestiaString("Go", comment: "")) { selection in
                    Task {
                        await self.executor.selectAndReceive(selection, action: .goTo)
                    }
                }
                }))
            }

            if let alternativeSurfaces = selection.body?.alternateSurfaceNames, alternativeSurfaces.count > 0 {
                let displaySurface = self.executor.get { $0.simulation.activeObserver.displayedSurface }
                let defaultSurfaceItem = UIAction(title: CelestiaString("Default", comment: "")) { _ in
                    self.executor.run { $0.simulation.activeObserver.displayedSurface = "" }
                }
                defaultSurfaceItem.state = displaySurface == "" ? .on : .off
                let otherSurfaces = alternativeSurfaces.map { name -> UIAction in
                    let action = UIAction(title: name) { _ in
                        self.executor.run { $0.simulation.activeObserver.displayedSurface = name }
                    }
                    action.state = displaySurface == name ? .on : .off
                    return action
                }
                let menu = UIMenu(title: CelestiaString("Alternate Surfaces", comment: ""), children: [defaultSurfaceItem] + otherSurfaces)
                actions.append(menu)
            }

            let markerOptions = (0...MarkerRepresentation.crosshair.rawValue).map { MarkerRepresentation(rawValue: $0)?.localizedTitle ?? "" } + [CelestiaString("Unmark", comment: "")]
            let markerMenu = UIMenu(title: CelestiaString("Mark", comment: ""), children: markerOptions.enumerated().map() { index, name -> UIAction in
                return UIAction(title: name) { [weak self] _ in
                    guard let self = self else { return }
                    if let marker = MarkerRepresentation(rawValue: UInt(index)) {
                        Task {
                            await self.executor.mark(selection, markerType: marker)
                        }
                    } else {
                        self.executor.run { $0.simulation.universe.unmark(selection) }
                    }
                }
            }
            )
            actions.append(UIMenu(title: "", options: .displayInline, children: [markerMenu]))
            return UIMenu(title: "", children: actions)
        }
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let loc = interaction.location(in: view)
        auxillaryContextMenuPreviewView.frame = CGRect(origin: loc, size: CGSize(width: 1, height: 1))
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = UIColor.clear
        return UITargetedPreview(view: auxillaryContextMenuPreviewView, parameters: parameters)
    }
}

@available(iOS 13.0, *)
extension UIContextMenuInteraction {
    func location(with targetGeometry: RenderingTargetGeometry) -> CGPoint {
        let viewLoc = location(in: view)
        let viewSize = view?.frame.size ?? targetGeometry.size
        let normalized = CGPoint(x: viewLoc.x / viewSize.width, y: viewLoc.y / viewSize.height)
        return CGPoint(x: normalized.x * targetGeometry.size.width, y: normalized.y * targetGeometry.size.height).scale(by: targetGeometry.scale)
    }
}

@available(iOS 13.0, *)
extension BrowserItem {
    @MainActor
    func createMenuItems(additionalItemName: String, with callback: @escaping (Selection) -> Void) -> UIMenu? {
        var items = [UIMenuElement]()

        if let ent = entry {
            items.append(UIAction(title: CelestiaString(additionalItemName, comment: ""), handler: { (_) in
                let selection = Selection(object: ent)
                guard selection.isEmpty else { return }
                callback(selection)
            }))
        }

        var childItems = [UIMenuElement]()
        for i in 0..<children.count {
            let subItemName = childName(at: Int(i))!
            let child = self.child(with: subItemName)!
            if let childMenu = child.createMenuItems(additionalItemName: additionalItemName, with: callback) {
                childItems.append(childMenu)
            }
        }
        if childItems.count > 0 {
            items.append(UIMenu(title: "", options: .displayInline, children: childItems))
        }
        return items.count == 0 ? nil : UIMenu(title: name, children: items)
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
            self.showError(error)
        }
    }
    nonisolated func celestiaAppCoreCursorShapeChanged(_ shape: CursorShape) {}
    nonisolated func celestiaAppCoreWatchedFlagDidChange(_ changedFlag: WatcherFlag) {}
}

extension CelestiaInteractionController {
    @objc private func mirroringDisplayLinkHandler() {
        targetInteractionView.layer.contents = renderingTargetContents
    }

    func startMirroring() {
        let displayLink = CADisplayLink(target: self, selector: #selector(mirroringDisplayLinkHandler))
        displayLink.add(to: .main, forMode: .common)
        mirroringDisplayLink = displayLink
        isMirroring = true
    }

    func stopMirroring() {
        mirroringDisplayLink?.invalidate()
        mirroringDisplayLink = nil
        targetInteractionView.layer.contents = nil
        isMirroring = false
    }
}

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

        executor.run { $0.keyDown(with: input, modifiers: modifiers) }
    }

    func keyUp(with input: String?, modifiers: UInt) {
        guard delegate?.celestiaInteractionControllerCanAcceptKeyEvents(self) == true else {
            return
        }

        executor.run { $0.keyUp(with: input, modifiers: modifiers) }
    }

    func openURL(_ url: UniformedURL) {
        if url.url.isFileURL {
            executor.run { $0.runScript(at: url.url.path) }
        } else {
            executor.run { $0.go(to: url.url.absoluteString) }
        }
    }
}

private extension CelestiaInteractionController {
    func startObservingGameControllerConnection() {
        if #available(iOS 14.0, *), let current = GCController.current {
            gameControllerChanged(current)
        } else if let firstController = GCController.controllers().first {
            gameControllerChanged(firstController)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(gameControllerConnected(_:)), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(gameControllerDisconnected(_:)), name: .GCControllerDidDisconnect, object: nil)
    }

    @objc func gameControllerConnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }

        gameControllerChanged(controller)
    }

    private func gameControllerChanged(_ controller: GCController) {
        var buttonA: GCDeviceButtonInput?
        var buttonB: GCDeviceButtonInput?
        var buttonX: GCDeviceButtonInput?
        var buttonY: GCDeviceButtonInput?
        var leftThumbstick: GCControllerDirectionPad?
        var rightThumbstick: GCControllerDirectionPad?
        var leftTrigger: GCDeviceButtonInput?
        var rightTrigger: GCDeviceButtonInput?
        var leftBumper: GCDeviceButtonInput?
        var rightBumper: GCDeviceButtonInput?
        var dpadUp: GCDeviceButtonInput?
        var dpadDown: GCDeviceButtonInput?
        var dpadLeft: GCDeviceButtonInput?
        var dpadRight: GCDeviceButtonInput?
        var buttonMenu: GCDeviceButtonInput?

        if let extendedGamepad = controller.extendedGamepad {
            buttonA = extendedGamepad.buttonA
            buttonB = extendedGamepad.buttonB
            buttonX = extendedGamepad.buttonX
            buttonY = extendedGamepad.buttonY
            leftThumbstick = extendedGamepad.leftThumbstick
            rightThumbstick = extendedGamepad.rightThumbstick
            leftTrigger = extendedGamepad.leftTrigger
            rightTrigger = extendedGamepad.rightTrigger
            leftBumper = extendedGamepad.leftShoulder
            rightBumper = extendedGamepad.rightShoulder
            dpadUp = extendedGamepad.dpad.up
            dpadDown = extendedGamepad.dpad.down
            dpadLeft = extendedGamepad.dpad.left
            dpadRight = extendedGamepad.dpad.right
            buttonMenu = extendedGamepad.buttonMenu
        } else if let microGamepad = controller.microGamepad {
            buttonA = microGamepad.buttonA
            buttonX = microGamepad.buttonX
            dpadUp = microGamepad.dpad.up
            dpadDown = microGamepad.dpad.down
            dpadLeft = microGamepad.dpad.left
            dpadRight = microGamepad.dpad.right
            buttonMenu = microGamepad.buttonMenu
        }

        let buttonStateChangedHandler = { [weak self] (key: UserDefaultsKey, defaultValue: GameControllerAction, pressed: Bool) in
            guard let self = self else { return }
            guard self.delegate?.celestiaInteractionControllerCanAcceptKeyEvents(self) == true else {
                return
            }
            let value: Int = self.userDefaults[key] ?? defaultValue.rawValue
            guard let action = GameControllerAction(rawValue: value) else { return }

            switch action {
            case .noop:
                break
            case .moveFaster:
                self.executor.run { pressed ? $0.joystickButtonDown(.button2) : $0.joystickButtonUp(.button2) }
            case .moveSlower:
                self.executor.run { pressed ? $0.joystickButtonDown(.button1) : $0.joystickButtonUp(.button1) }
            case .stopSpeed:
                if !pressed {
                    self.executor.run { $0.charEnter(115) }
                }
            case .reverseSpeed:
                if !pressed {
                    self.executor.run { $0.charEnter(113) }
                }
            case .reverseOrientation:
                if !pressed {
                    self.executor.run { $0.simulation.reverseObserverOrientation() }
                }
            case .tapCenter:
                self.executor.run { core in
                    let size = core.size
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    pressed ? core.mouseButtonDown(at: center, modifiers: 0, with: .left) : core.mouseButtonUp(at: center, modifiers: 0, with: .left)
                }
            case .goTo:
                if !pressed {
                    self.executor.run { $0.charEnter(103) }
                }
            case .esc:
                if !pressed {
                    self.executor.run { $0.charEnter(27) }
                }
            case .pitchUp:
                self.executor.run { pressed ? $0.keyDown(26) : $0.keyUp(26) }
            case .pitchDown:
                self.executor.run { pressed ? $0.keyDown(32) : $0.keyUp(32) }
            case .yawLeft:
                self.executor.run { pressed ? $0.keyDown(28) : $0.keyUp(28) }
            case .yawRight:
                self.executor.run { pressed ? $0.keyDown(30) : $0.keyUp(30) }
            case .rollLeft:
                self.executor.run { pressed ? $0.keyDown(31) : $0.keyUp(31) }
            case .rollRight:
                self.executor.run { pressed ? $0.keyDown(33) : $0.keyUp(33) }
            }
        }
        let thumbstickChangedHandler = { [weak self] (xValue: Float, yValue: Float) in
            guard let self = self else { return }
            guard self.delegate?.celestiaInteractionControllerCanAcceptKeyEvents(self) == true else {
                return
            }
            let shouldInvertX = self.userDefaults[.gameControllerInvertX] == true
            let shouldInvertY = self.userDefaults[.gameControllerInvertY] == true
            self.executor.run { core in
                core.joystickAxis(.X, amount: shouldInvertX ? -xValue : xValue)
                core.joystickAxis(.Y, amount: shouldInvertY ? -yValue : yValue)
            }
        }
        buttonMenu?.valueChangedHandler = { [weak self] _, _, pressed in
            guard let self = self else { return }
            guard self.delegate?.celestiaInteractionControllerCanAcceptKeyEvents(self) == true else {
                return
            }
            if !pressed {
                self.delegate?.celestiaInteractionControllerRequestShowActionMenu(self)
            }
        }
        leftThumbstick?.valueChangedHandler = { _, xValue, yValue in
            thumbstickChangedHandler(xValue, yValue)
        }
        rightThumbstick?.valueChangedHandler = { _, xValue, yValue in
            thumbstickChangedHandler(xValue, yValue)
        }
        buttonA?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapA, .moveSlower, pressed)
        }
        buttonB?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapB, .noop, pressed)
        }
        buttonX?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapX, .moveFaster, pressed)
        }
        buttonY?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapY, .noop, pressed)
        }
        leftTrigger?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapLT, .rollLeft, pressed)
        }
        rightTrigger?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapRT, .rollRight, pressed)
        }
        leftBumper?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapLB, .noop, pressed)
        }
        rightBumper?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapRB, .noop, pressed)
        }
        dpadLeft?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapDpadLeft, .rollLeft, pressed)
        }
        dpadRight?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapDpadRight, .rollRight, pressed)
        }
        dpadUp?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapDpadUp, .pitchUp, pressed)
        }
        dpadDown?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.gameControllerRemapDpadDown, .pitchDown, pressed)
        }

        connectedGameController = controller
    }

    @objc func gameControllerDisconnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }

        if connectedGameController == controller {
            connectedGameController = nil
        }
    }
}

private extension CGPoint {
    func scale(by factor: CGFloat) -> CGPoint {
        return applying(CGAffineTransform(scaleX: factor, y: factor))
    }
}
