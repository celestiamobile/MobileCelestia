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

import CelestiaCore
import CelestiaFoundation
import CelestiaUI
#if !targetEnvironment(macCatalyst)
import CoreMotion
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
    func celestiaInteractionControllerCanAcceptKeyEvents(_ celestiaInteractionController: CelestiaInteractionController) -> Bool
}

@MainActor
protocol RenderingTargetInformationProvider: AnyObject {
    var targetGeometry: RenderingTargetGeometry { get }
    var targetContents: Any? { get }
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
        if #available(iOS 15, *), subscriptionManager.transactionInfo() != nil, let stringValue: String = userDefaults[UserDefaultsKey.toolbarItems] {
            var actions = QuickAction.from(stringValue) ?? QuickAction.defaultItems
            if !actions.contains(.menu) {
                actions.append(.menu)
            }
            return actions
        }
        return QuickAction.defaultItems
    }()
    private lazy var activeControlView = CelestiaControlView(items: controlViewActions.compactMap { action in
        switch action {
        case .mode:
            CelestiaControlButton.toggle(accessibilityLabel:  CelestiaString("Toggle Interaction Mode", comment: "Touch interaction mode"), offImage: UIImage(systemName: "cube"), offAction: .switchToObject, offAccessibilityValue: CelestiaString("Camera Mode", comment: "Interaction mode for touch"), onImage: UIImage(systemName: "video"), onAction: .switchToCamera, onAccessibilityValue: CelestiaString("Object Mode", comment: "Interaction mode for touch"))
        case .info:
            CelestiaControlButton.tap(image: UIImage(systemName: "info.circle"), action: .info, accessibilityLabel: CelestiaString("Get Info", comment: "Action for getting info about current selected object"))
        case .search:
            CelestiaControlButton.tap(image: UIImage(systemName: "magnifyingglass.circle"), action: .search, accessibilityLabel: CelestiaString("Search", comment: ""))
        case .menu:
            CelestiaControlButton.tap(image: UIImage(systemName: "line.3.horizontal.circle") ?? UIImage(systemName: "line.horizontal.3.circle"), action: .showMenu, accessibilityLabel: CelestiaString("Menu", comment: "Menu button"))
        case .hide:
            CelestiaControlButton.tap(image: UIImage(systemName: "xmark.circle"), action: .hide, accessibilityLabel: CelestiaString("Hide", comment: "Action to hide the tool overlay"))
        case .zoomIn:
            CelestiaControlButton.pressAndHold(image: UIImage(systemName: "plus.circle"), action: .zoomIn, accessibilityLabel: CelestiaString("Zoom In", comment: ""))
        case .zoomOut:
            CelestiaControlButton.pressAndHold(image: UIImage(systemName: "minus.circle"), action: .zoomOut, accessibilityLabel: CelestiaString("Zoom Out", comment: ""))
        case .go:
            CelestiaControlButton.tap(image: UIImage(systemName: "paperplane.circle"), action: .go, accessibilityLabel: CelestiaString("Go", comment: "Go to an object"))
        }
    })
    #endif

    // MARK: gesture
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
    #endif

    private var zoomTimer: Timer?

    #if !targetEnvironment(macCatalyst)
    private var isObservingGyroscopeUpdates = false
    private lazy var motionManager: CMMotionManager = {
        let motionManager = CMMotionManager()
        motionManager.deviceMotionUpdateInterval = 0.02
        return motionManager
    }()
    var lastRotationQuaternion: simd_quatf?
    #endif

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
    }
}

#if !targetEnvironment(macCatalyst)
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
            hideControlView()
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

    private func hideControlView() {
        guard currentHideAnimator == nil else { return }
        currentShowAnimator?.stopAnimation(true)
        currentShowAnimator?.finishAnimation(at: .current)
        currentShowAnimator = nil

        let animator = UIViewPropertyAnimator(duration: Constants.controlViewHideAnimationDuration, curve: .linear) { [weak self] in
            self?.activeControlView.alpha = 0
        }

        currentHideAnimator = animator
        animator.startAnimation()


        Task {
            await animator.addCompletion()
            self.currentHideAnimator = nil
            self.isControlViewVisible = false
        }
    }

    private func showControlView() {
        guard currentShowAnimator == nil else { return }
        currentHideAnimator?.stopAnimation(true)
        currentHideAnimator?.finishAnimation(at: .current)
        currentHideAnimator = nil

        let animator = UIViewPropertyAnimator(duration: Constants.controlViewShowAnimationDuration, curve: .linear) { [weak self] in
            self?.activeControlView.alpha = 1
        }

        currentShowAnimator = animator
        animator.startAnimation()

        Task {
            await animator.addCompletion()
            self.currentShowAnimator = nil
            self.isControlViewVisible = true
        }
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
        #endif
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
    @objc private func handlePanZoom(_ pan: UIPanGestureRecognizer) {
#if !targetEnvironment(macCatalyst)
        showControlViewIfNeeded()
#endif

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
#if !targetEnvironment(macCatalyst)
        showControlViewIfNeeded()
#endif

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
            currentPanStartPoint = MacBridge.currentMouseLocation
            NSCursor.hide()
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
            NSCursor.unhide()
            #endif
            executor.runAsynchronously { $0.mouseButtonUp(at: location, modifiers: UInt(modifiers.rawValue), with: button) }
            currentPanPoint = nil
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
#if !targetEnvironment(macCatalyst)
        showControlViewIfNeeded()
#endif

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
#if !targetEnvironment(macCatalyst)
        showControlViewIfNeeded()
#endif

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
        return UIDeferredMenuElement { [weak self, weak interaction] completion in
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

                completion(self.contextMenuForSelection(selection: selection))
            }
        }
    }

    private func contextMenuForSelection(selection: Selection) -> [UIMenuElement] {
        let titleAction = UIAction(title: core.simulation.universe.name(for: selection)) { _ in }
        titleAction.attributes = [.disabled]
        var actions: [UIMenuElement] = [titleAction]

        actions.append(UIMenu(options: .displayInline, children: [
            UIAction(title: CelestiaString("Get Info", comment: "Action for getting info about current selected object")) { [weak self] _ in
                guard let self else { return }
                self.delegate?.celestiaInteractionController(self, requestShowInfoWithSelection: selection)
            }
        ]))

        actions.append(UIMenu(options: .displayInline, children: CelestiaAction.allCases.map { action in
            return UIAction(title: action.description) { [weak self] _ in
                guard let self else { return }
                Task {
                    await self.executor.selectAndReceive(selection, action: action)
                }
            }
        }))

        if let entry = selection.object {
            let browserItem = BrowserItem(name: core.simulation.universe.name(for: selection), catEntry: entry, provider: core.simulation.universe)
            actions.append(UIMenu(options: .displayInline, children: browserItem.children.compactMap { $0.createMenuItems(object: entry, additionalItemName: CelestiaString("Go", comment: "Go to an object"), additionalItemHandler: { [weak self] selection in
                guard let self else { return }
                Task {
                    await self.executor.selectAndReceive(selection, action: .goTo)
                }
            }) { [weak self] selection in
                guard let self else { return }
                self.delegate?.celestiaInteractionController(self, requestShowSubsystemWithSelection: selection)
            }}))
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

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
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
    @MainActor
    func createMenuItems(object: AstroObject, additionalItemName: String, additionalItemHandler: @escaping (Selection) -> Void, showMoreHandler: @escaping (Selection) -> Void) -> UIMenu? {
        var items = [UIMenuElement]()
        var parent = object
        if let entry {
            parent = entry
            items.append(UIAction(title: additionalItemName, handler: { _ in
                let selection = Selection(object: entry)
                guard !selection.isEmpty else { return }
                additionalItemHandler(selection)
            }))
        }

        var childItems = [UIMenuElement]()
        var shouldInsertShowMore = false
        for i in 0..<children.count {
            if i > 50 {
                shouldInsertShowMore = true
                break
            }
            let subItemName = childName(at: Int(i))!
            let child = child(with: subItemName)!
            if let childMenu = child.createMenuItems(object: parent, additionalItemName: additionalItemName, additionalItemHandler: additionalItemHandler, showMoreHandler: showMoreHandler) {
                childItems.append(childMenu)
            }
        }
        if childItems.count > 0 {
            items.append(UIMenu(options: .displayInline, children: childItems))
        }
        if shouldInsertShowMore {
            items.append(UIMenu(options: .displayInline, children: [
                UIAction(title: CelestiaString("Show More…", comment: "Menu action to indicate that more items that are not shown in the menu"), handler: { _ in
                    let selection = Selection(object: parent)
                    guard !selection.isEmpty else { return }
                    showMoreHandler(selection)
                })
            ]))
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

        executor.runAsynchronously { $0.keyDown(with: input, modifiers: modifiers) }
    }

    func keyUp(with input: String?, modifiers: UInt) {
        guard delegate?.celestiaInteractionControllerCanAcceptKeyEvents(self) == true else {
            return
        }

        executor.runAsynchronously { $0.keyUp(with: input, modifiers: modifiers) }
    }

    func openURL(_ url: UniformedURL) {
        if url.url.isFileURL {
            executor.runAsynchronously { $0.runScript(at: url.url.path) }
        } else {
            executor.runAsynchronously { $0.go(to: url.url.absoluteString) }
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

                    let deviceOrientation = self.view.window?.windowScene?.interfaceOrientation ?? .portrait

                    let baseQuat = simd_quatf(deviceMotionData.attitude.quaternion)
                    let currentQuat: simd_quatf
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
                        break
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

private extension CGPoint {
    func scale(by factor: CGFloat) -> CGPoint {
        return applying(CGAffineTransform(scaleX: factor, y: factor))
    }
}
