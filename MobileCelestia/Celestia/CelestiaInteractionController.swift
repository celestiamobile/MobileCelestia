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
}

extension CelestiaAction {
    static var allCases: [CelestiaAction] {
        return [.goTo, .center, .follow, .chase, .syncOrbit, .lock, .goToSurface]
    }
}

extension CelestiaAppCore {
    func receive(_ action: CelestiaAction) {
        if textEnterMode != .normal {
            textEnterMode = .normal
        }
        charEnter(action.rawValue)
    }
}

protocol CelestiaInteractionControllerDelegate: class {
    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestShowActionMenuWithSelection selection: CelestiaSelection)
    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestShowInfoWithSelection selection: CelestiaSelection)
    func celestiaInteractionController(_ celestiaInteractionController: CelestiaInteractionController, requestWebInfo webURL: URL)
}

protocol RenderingTargetInformationProvider: class {
    var targetGeometry: RenderingTargetGeometry { get }
    var targetImage: UIImage { get }
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

    struct Constant {
        static let controlViewTrailingMargin: CGFloat = 8
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
        CelestiaControlButton.tap(image: #imageLiteral(resourceName: "control_info"), action: .info),
        CelestiaControlButton.tap(image: #imageLiteral(resourceName: "control_action_menu"), action: .showMenu),
        CelestiaControlButton.tap(image: #imageLiteral(resourceName: "control_hide"), action: .hide),
    ])
    #else
    private lazy var activeControlView = CelestiaControlView(items: [
        CelestiaControlButton.toggle(offImage: #imageLiteral(resourceName: "control_mode_object"), offAction: .switchToObject, onImage: #imageLiteral(resourceName: "control_mode_camera"), onAction: .switchToCamera),
        CelestiaControlButton.pressAndHold(image: #imageLiteral(resourceName: "control_zoom_in"), action: .zoomIn),
        CelestiaControlButton.pressAndHold(image: #imageLiteral(resourceName: "control_zoom_out"), action: .zoomOut),
        CelestiaControlButton.tap(image: #imageLiteral(resourceName: "control_info"), action: .info),
        CelestiaControlButton.tap(image: #imageLiteral(resourceName: "control_action_menu"), action: .showMenu),
        CelestiaControlButton.tap(image: #imageLiteral(resourceName: "control_hide"), action: .hide),
    ])
    #endif

    private lazy var inactiveControlView = CelestiaControlView(items: [
        CelestiaControlButton.tap(image: #imageLiteral(resourceName: "control_show"), action: .show),
    ])

    private var currentControlView: CelestiaControlView?

    private var pendingSelection: CelestiaSelection?

    // MARK: gesture
    private var oneFingerStartPoint: CGPoint?
    private var currentPanDistance: CGFloat?

    private lazy var core = CelestiaAppCore.shared

    weak var delegate: CelestiaInteractionControllerDelegate?
    weak var targetProvider: RenderingTargetInformationProvider?

    private var zoomTimer: Timer?

    private var renderingTargetGeometry: RenderingTargetGeometry {
        return targetProvider?.targetGeometry ?? RenderingTargetGeometry(size: view.frame.size, scale: view.contentScaleFactor)
    }

    private var renderingTargetImage: UIImage? {
        return targetProvider?.targetImage
    }

    private lazy var targetInteractionView = UIImageView()
    private lazy var auxillaryContextMenuPreviewView = UIView()
    private lazy var mirroringDisplayLink = CADisplayLink(target: self, selector: #selector(mirroringDisplayLinkHandler))
    private var isMirroring = false

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
        inactiveControlView.delegate = self
        activeControlView.translatesAutoresizingMaskIntoConstraints = false
        inactiveControlView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(activeControlView)
        container.addSubview(inactiveControlView)

        NSLayoutConstraint.activate([
            activeControlView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            activeControlView.trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor, constant: -Constant.controlViewTrailingMargin),
            inactiveControlView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            inactiveControlView.leadingAnchor.constraint(equalTo: container.trailingAnchor)
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
        let sel = core.simulation.selection
        switch action {
        case .showMenu:
            delegate?.celestiaInteractionController(self, requestShowActionMenuWithSelection: sel)
        case .info:
            delegate?.celestiaInteractionController(self, requestShowInfoWithSelection: sel)
        case .hide:
            hideCurrentControlViewToShow(inactiveControlView)
        case .show:
            hideCurrentControlViewToShow(activeControlView)
        default:
            break
        }
    }

    private func hideCurrentControlViewToShow(_ anotherView: CelestiaControlView) {
        guard let activeView = currentControlView else { return }
        guard let superview = activeView.superview else { return }
        guard anotherView != activeView else { return }

        guard let activeViewConstraint = activeView.constraintsAffectingLayout(for: .horizontal).filter({ ($0.firstItem as? UIView) == activeView && ($0.secondItem as? NSObject) == superview.safeAreaLayoutGuide }).first else {
            return
        }
        guard let anotherViewConstrant = anotherView.constraintsAffectingLayout(for: .horizontal).filter({ ($0.firstItem as? UIView) == anotherView && ($0.secondItem as? UIView) == superview }).first else {
            return
        }

        activeViewConstraint.isActive = false
        activeView.leadingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
        let hideAnimator = UIViewPropertyAnimator(duration: Constant.controlViewHideAnimationDuration, curve: .linear) { [weak self] in
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
        }

        let showAnimator = UIViewPropertyAnimator(duration: Constant.controlViewShowAnimationDuration, curve: .linear) { [weak self] in
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
        }

        hideAnimator.addCompletion { (_) in
            anotherViewConstrant.isActive = false
            anotherView.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: -Constant.controlViewTrailingMargin).isActive = true
            showAnimator.startAnimation()
        }

        showAnimator.addAnimations { [weak self] in
            self?.currentControlView = anotherView
        }

        hideAnimator.startAnimation()
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

        let rightEdge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        rightEdge.edges = .right
        pan1.require(toFail: rightEdge)
        targetInteractionView.addGestureRecognizer(rightEdge)

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
            NSCursor.hide()
            #endif
            oneFingerStartPoint = location
            core.mouseButtonDown(at: location, modifiers: UInt(modifiers.rawValue), with: button)
        case .changed:
            let current = oneFingerStartPoint!
            let offset = CGPoint(x: location.x - current.x, y: location.y - current.y)
            oneFingerStartPoint = location
            core.mouseMove(by: offset, modifiers: UInt(modifiers.rawValue), with: button)
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            #if targetEnvironment(macCatalyst)
            NSCursor.unhide()
            #endif
            core.mouseButtonUp(at: location, modifiers: UInt(modifiers.rawValue), with: button)
            oneFingerStartPoint = nil
        }
    }

    #if !targetEnvironment(macCatalyst)
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
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
            currentPanDistance = length
            core.mouseButtonDown(at: center, modifiers: 0, with: .left)
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
            let delta = length / currentPanDistance!
            // FIXME: 8 is a magic number
            let y = (1 - delta) * currentPanDistance! / 8
            zoom(deltaY: y)
            currentPanDistance = length
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            currentPanDistance = nil
        }
    }
    #endif

    @objc private func handleTap(_ tap: UITapGestureRecognizer) {
        switch tap.state {
        case .ended:
            let location = tap.location(with: renderingTargetGeometry)
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
            delegate?.celestiaInteractionController(self, requestShowActionMenuWithSelection: sel)
        default:
            break
        }
    }

    private func zoom(deltaY: CGFloat, modifiers: UInt = 0, scrolling: Bool = false) {
        if scrolling || interactionMode == .object {
            core.mouseWheel(by: deltaY, modifiers: modifiers)
        } else {
            core.mouseMove(by: CGPoint(x: 0, y: deltaY), modifiers: UInt(UIKeyModifierFlags.shift.rawValue), with: .left)
        }
    }
}

extension CelestiaInteractionController: UIGestureRecognizerDelegate {
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

@available(iOS 13.0, *)
extension CelestiaInteractionController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        core.mouseButtonDown(at: interaction.location(with: renderingTargetGeometry), modifiers: 0, with: .right)
        core.mouseButtonUp(at: interaction.location(with: renderingTargetGeometry), modifiers: 0, with: .right)

        guard let selection = pendingSelection else { return nil }
        pendingSelection = nil
        let core = self.core

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ -> UIMenu? in
            let titleAction = UIAction(title: core.simulation.universe.name(for: selection)) { _ in }
            titleAction.attributes = [.disabled]
            var actions: [UIMenuElement] = [titleAction]

            actions.append(UIMenu(title: "", options: .displayInline, children: CelestiaAction.allCases.map { action in
                return UIAction(title: action.description) { (_) in
                    core.simulation.selection = selection
                    core.receive(action)
                }
            }))

            if let entry = selection.object {
                let browserItem = CelestiaBrowserItem(name: core.simulation.universe.name(for: selection), catEntry: entry, provider: core.simulation.universe)
                actions.append(UIMenu(title: "", options: .displayInline, children: browserItem.children.compactMap { $0.createMenuItems(additionalItemName: CelestiaString("Go", comment: "")) { (selection) in
                    core.simulation.selection = selection
                    core.receive(.goTo)
                }
                }))
            }

            if let alternativeSurfaces = selection.body?.alternateSurfaceNames, alternativeSurfaces.count > 0 {
                let displaySurface = core.simulation.activeObserver.displayedSurface
                let defaultSurfaceItem = UIAction(title: CelestiaString("Default", comment: "")) { _ in
                    core.simulation.activeObserver.displayedSurface = ""
                }
                defaultSurfaceItem.state = displaySurface == "" ? .on : .off
                let otherSurfaces = alternativeSurfaces.map { name -> UIAction in
                    let action = UIAction(title: name) { _ in
                        core.simulation.activeObserver.displayedSurface = name
                    }
                    action.state = displaySurface == name ? .on : .off
                    return action
                }
                let menu = UIMenu(title: "Alternate Surfaces", children: [defaultSurfaceItem] + otherSurfaces)
                actions.append(menu)
            }

            let markerOptions = (0...CelestiaMarkerRepresentation.crosshair.rawValue).map { CelestiaMarkerRepresentation(rawValue: $0)?.localizedTitle ?? "" } + [CelestiaString("Unmark", comment: "")]
            let markerMenu = UIMenu(title: CelestiaString("Mark", comment: ""), children: markerOptions.enumerated().map() { index, name -> UIAction in
                return UIAction(title: name) { [weak self] _ in
                    guard let self = self else { return }
                    if let marker = CelestiaMarkerRepresentation(rawValue: UInt(index)) {
                        self.core.simulation.universe.mark(selection, with: marker)
                        self.core.showMarkers = true
                    } else {
                        self.core.simulation.universe.unmark(selection)
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
extension CelestiaBrowserItem {
    func createMenuItems(additionalItemName: String, with callback: @escaping (CelestiaSelection) -> Void) -> UIMenu? {
        var items = [UIMenuElement]()

        if let ent = entry {
            items.append(UIAction(title: CelestiaString(additionalItemName, comment: ""), handler: { (_) in
                guard let selection = CelestiaSelection(object: ent) else { return }
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

extension CelestiaInteractionController: CelestiaAppCoreDelegate {
    func celestiaAppCoreFatalErrorHappened(_ error: String) {}

    func celestiaAppCoreCursorShapeChanged(_ shape: CursorShape) {}

    func celestiaAppCoreCursorDidRequestContextMenu(at location: CGPoint, with selection: CelestiaSelection) {
        pendingSelection = selection
    }

    func celestiaAppCoreWatchedFlagDidChange(_ changedFlag: CelestiaWatcherFlag) {}
}

extension CelestiaInteractionController {
    @objc private func mirroringDisplayLinkHandler() {
        targetInteractionView.image = renderingTargetImage
    }

    func startMirroring() {
        stopMirroring()
        mirroringDisplayLink.add(to: .main, forMode: .common)
        isMirroring = true
    }

    func stopMirroring() {
        guard isMirroring else { return }
        mirroringDisplayLink.remove(from: .main, forMode: .common)
        targetInteractionView.image = nil
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
        core.keyDown(with: input, modifiers: modifiers)
    }

    func keyUp(with input: String?, modifiers: UInt) {
        core.keyUp(with: input, modifiers: modifiers)
    }

    func openURL(_ url: URL, external: Bool) {
        if url.isFileURL {
            let uniformed = UniformedURL(url: url, securityScoped: external)
            core.runScript(at: uniformed.url.path)
        } else {
            core.go(to: url.absoluteString)
        }
    }
}

private extension CGPoint {
    func scale(by factor: CGFloat) -> CGPoint {
        return applying(CGAffineTransform(scaleX: factor, y: factor))
    }
}
