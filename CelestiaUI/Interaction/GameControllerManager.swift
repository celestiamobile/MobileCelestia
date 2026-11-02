// GameControllerManager.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import Foundation
import GameController
import UIKit

extension GCController: @unchecked @retroactive Sendable {}

public class GameControllerManager: @unchecked Sendable {
    private let executor: AsyncProviderExecutor
    private let canAcceptEvents: () -> Bool
    private let actionRemapper: ((GameControllerButton) -> GameControllerAction?)?
    private let thumbstickStatus: ((GameControllerThumbstick) -> Bool?)?
    private let axisInversion: ((GameControllerThumbstickAxis) -> Bool)?
    private let menuButtonHandler: (() -> Void)?
    private let connectedGameControllerChanged: ((GCController?) -> Void)?

    @MainActor private var connectedGameController: GCController?
    @MainActor private var activeButtons: [GameControllerButton: GameControllerAction] = [:]
    @MainActor private var activeThumbsticks: Set<GameControllerThumbstick> = []

    @MainActor
    public init(
        executor: AsyncProviderExecutor,
        canAcceptEvents: @escaping () -> Bool,
        actionRemapper: ((GameControllerButton) -> GameControllerAction?)? = nil,
        thumbstickStatus: ((GameControllerThumbstick) -> Bool?)? = nil,
        axisInversion: ((GameControllerThumbstickAxis) -> Bool)? = nil,
        menuButtonHandler: (() -> Void)? = nil,
        connectedGameControllerChanged: ((GCController?) -> Void)? = nil
    ) {
        self.executor = executor
        self.canAcceptEvents = canAcceptEvents
        self.actionRemapper = actionRemapper
        self.thumbstickStatus = thumbstickStatus
        self.axisInversion = axisInversion
        self.menuButtonHandler = menuButtonHandler
        self.connectedGameControllerChanged = connectedGameControllerChanged

        startObservingGameControllerConnection()
    }

    @MainActor
    private func startObservingGameControllerConnection() {
        if let current = GCController.current {
            gameControllerChanged(current)
        } else if let firstController = GCController.controllers().first {
            gameControllerChanged(firstController)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(gameControllerConnected(_:)), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(gameControllerDisconnected(_:)), name: .GCControllerDidDisconnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(inputFocusLost(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(inputFocusLost(_:)), name: UIWindow.didResignKeyNotification, object: nil)
    }

    @objc private func gameControllerConnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }

        Task { @MainActor in
            gameControllerChanged(controller)
        }
    }

    @objc private func gameControllerDisconnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        Task { @MainActor in
            if connectedGameController == controller {
                resetInput()
                connectedGameController = nil
                connectedGameControllerChanged?(nil)
            }
        }
    }

    @objc private func inputFocusLost(_ notification: Notification) {
        Task { @MainActor in
            resetInput()
        }
    }

    @MainActor private func resetInput() {
        for action in Set(activeButtons.values) {
            sendButtonAction(action, pressed: false, performReleaseAction: false)
        }
        activeButtons.removeAll()
        for thumbstick in activeThumbsticks {
            sendThumbstick(thumbstick, xValue: 0, yValue: 0)
        }
        activeThumbsticks.removeAll()
    }

    private func sendButtonAction(_ action: GameControllerAction, pressed: Bool, performReleaseAction: Bool = true) {
        executor.runAsynchronously { core in
            switch action {
            case .noop:
                break
            case .moveFaster:
                pressed ? core.joystickButtonDown(.button2) : core.joystickButtonUp(.button2)
            case .moveSlower:
                pressed ? core.joystickButtonDown(.button1) : core.joystickButtonUp(.button1)
            case .stopSpeed:
                if !pressed && performReleaseAction { core.receive(.stop) }
            case .reverseSpeed:
                if !pressed && performReleaseAction { core.receive(.reverseSpeed) }
            case .reverseOrientation:
                if !pressed && performReleaseAction { core.simulation.reverseObserverOrientation() }
            case .tapCenter:
                let size = core.size
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                pressed ? core.mouseButtonDown(at: center, modifiers: 0, with: .left) : core.mouseButtonUp(at: center, modifiers: 0, with: .left)
            case .goTo:
                if !pressed && performReleaseAction { core.receive(.goTo) }
            case .esc:
                if !pressed && performReleaseAction { core.receive(.cancelScript) }
            case .pitchUp:
                pressed ? core.keyDown(26) : core.keyUp(26)
            case .pitchDown:
                pressed ? core.keyDown(32) : core.keyUp(32)
            case .yawLeft:
                pressed ? core.keyDown(28) : core.keyUp(28)
            case .yawRight:
                pressed ? core.keyDown(30) : core.keyUp(30)
            case .rollLeft:
                pressed ? core.keyDown(31) : core.keyUp(31)
            case .rollRight:
                pressed ? core.keyDown(33) : core.keyUp(33)
            }
        }
    }

    private func sendThumbstick(_ thumbstick: GameControllerThumbstick, xValue: Float, yValue: Float) {
        executor.runAsynchronously { core in
            core.joystickAxis(thumbstick == .right ? .rightX : .X, amount: xValue)
            core.joystickAxis(thumbstick == .right ? .rightY : .Y, amount: yValue)
        }
    }

    @MainActor private func gameControllerChanged(_ controller: GCController) {
        resetInput()
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

        let buttonStateChangedHandler = { [weak self, weak controller] (button: GameControllerButton, defaultAction: GameControllerAction, pressed: Bool) in
            guard let self else { return }
            Task { @MainActor [weak controller] in
                guard let controller, self.connectedGameController == controller else { return }
                guard self.canAcceptEvents() else {
                    self.resetInput()
                    return
                }
                let action: GameControllerAction
                if pressed {
                    guard self.activeButtons[button] == nil else { return }
                    action = self.actionRemapper?(button) ?? defaultAction
                    let alreadyPressed = self.activeButtons.values.contains(action)
                    self.activeButtons[button] = action
                    guard !alreadyPressed else { return }
                } else {
                    guard let acceptedAction = self.activeButtons.removeValue(forKey: button) else { return }
                    action = acceptedAction
                    guard !self.activeButtons.values.contains(action) else { return }
                }
                self.sendButtonAction(action, pressed: pressed)
            }
        }
        let thumbstickChangedHandler = { [weak self, weak controller] (thumbstick: GameControllerThumbstick, xValue: Float, yValue: Float) in
            guard let self else { return }
            Task { @MainActor [weak controller] in
                guard let controller, self.connectedGameController == controller else { return }
                guard self.canAcceptEvents() else {
                    self.resetInput()
                    return
                }
                guard self.thumbstickStatus?(thumbstick) ?? true else {
                    self.activeThumbsticks.remove(thumbstick)
                    self.sendThumbstick(thumbstick, xValue: 0, yValue: 0)
                    return
                }
                let shouldInvertX = self.axisInversion?(.X) ?? false
                let shouldInvertY = self.axisInversion?(.Y) ?? false
                self.activeThumbsticks.insert(thumbstick)
                self.sendThumbstick(thumbstick, xValue: shouldInvertX ? -xValue : xValue, yValue: shouldInvertY ? -yValue : yValue)
            }
        }
        buttonMenu?.valueChangedHandler = { [weak self, weak controller] _, _, pressed in
            guard let self = self else { return }
            if !pressed {
                Task { @MainActor [weak controller] in
                    guard let controller, self.connectedGameController == controller else { return }
                    guard self.canAcceptEvents() else {
                        self.resetInput()
                        return
                    }
                    self.menuButtonHandler?()
                }
            }
        }
        leftThumbstick?.valueChangedHandler = { _, xValue, yValue in
            thumbstickChangedHandler(.left, xValue, yValue)
        }
        rightThumbstick?.valueChangedHandler = { _, xValue, yValue in
            thumbstickChangedHandler(.right, xValue, yValue)
        }
        buttonA?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.A, .moveSlower, pressed)
        }
        buttonB?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.B, .noop, pressed)
        }
        buttonX?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.X, .moveFaster, pressed)
        }
        buttonY?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.Y, .noop, pressed)
        }
        leftTrigger?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.LT, .rollLeft, pressed)
        }
        rightTrigger?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.RT, .rollRight, pressed)
        }
        leftBumper?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.LB, .noop, pressed)
        }
        rightBumper?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.RB, .noop, pressed)
        }
        dpadLeft?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.dpadLeft, .rollLeft, pressed)
        }
        dpadRight?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.dpadRight, .rollRight, pressed)
        }
        dpadUp?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.dpadUp, .pitchUp, pressed)
        }
        dpadDown?.valueChangedHandler = { _, _, pressed in
            buttonStateChangedHandler(.dpadDown, .pitchDown, pressed)
        }

        connectedGameController = controller
        connectedGameControllerChanged?(controller)
    }
}
