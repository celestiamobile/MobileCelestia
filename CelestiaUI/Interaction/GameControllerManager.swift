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
#if os(visionOS)
import simd
#endif

extension GCController: @unchecked @retroactive Sendable {}

public class GameControllerManager: @unchecked Sendable {
    private let executor: AsyncProviderExecutor
    private let canAcceptEvents: () -> Bool
    private let actionRemapper: ((GameControllerButton) -> GameControllerAction?)?
    private let thumbstickStatus: ((GameControllerThumbstick) -> Bool?)?
    private let axisInversion: ((GameControllerThumbstickAxis) -> Bool)?
    private let menuButtonHandler: (() -> Void)?
    private let connectedGameControllerChanged: ((GCController?) -> Void)?

    private var connectedGameController: GCController?

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
                connectedGameController = nil
                connectedGameControllerChanged?(nil)
            }
        }
    }

    @MainActor private func gameControllerChanged(_ controller: GCController) {
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

        let buttonStateChangedHandler = { [weak self] (button: GameControllerButton, defaultAction: GameControllerAction, pressed: Bool) in
            guard let self else { return }
            guard self.canAcceptEvents() else {
                return
            }
            Task { @MainActor in
                let action = self.actionRemapper?(button) ?? defaultAction
                switch action {
                case .noop:
                    break
                case .moveFaster:
                    await self.executor.run { pressed ? $0.joystickButtonDown(.button2) : $0.joystickButtonUp(.button2) }
                case .moveSlower:
                    await self.executor.run { pressed ? $0.joystickButtonDown(.button1) : $0.joystickButtonUp(.button1) }
                case .stopSpeed:
                    if !pressed {
                        await self.executor.run { $0.receive(.stop) }
                    }
                case .reverseSpeed:
                    if !pressed {
                        await self.executor.run { $0.receive(.reverseSpeed) }
                    }
                case .reverseOrientation:
                    if !pressed {
                        await self.executor.run { $0.simulation.reverseObserverOrientation() }
                    }
                case .tapCenter:
                    await self.executor.run { core in
                        #if os(visionOS)
                        pressed ? core.touchDown(simd_float3(x: 0, y: 0, z: -1)) : core.touchUp(simd_float3(x: 0, y: 0, z: -1))
                        #else
                        let size = core.size
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        pressed ? core.mouseButtonDown(at: center, modifiers: 0, with: .left) : core.mouseButtonUp(at: center, modifiers: 0, with: .left)
                        #endif
                    }
                case .goTo:
                    if !pressed {
                        await self.executor.run { $0.receive(.goTo) }
                    }
                case .esc:
                    if !pressed {
                        await self.executor.run { $0.receive(.cancelScript) }
                    }
                case .pitchUp:
                    await self.executor.run { pressed ? $0.keyDown(26) : $0.keyUp(26) }
                case .pitchDown:
                    await self.executor.run { pressed ? $0.keyDown(32) : $0.keyUp(32) }
                case .yawLeft:
                    await self.executor.run { pressed ? $0.keyDown(28) : $0.keyUp(28) }
                case .yawRight:
                    await self.executor.run { pressed ? $0.keyDown(30) : $0.keyUp(30) }
                case .rollLeft:
                    await self.executor.run { pressed ? $0.keyDown(31) : $0.keyUp(31) }
                case .rollRight:
                    await self.executor.run { pressed ? $0.keyDown(33) : $0.keyUp(33) }
                }
            }
        }
        let thumbstickChangedHandler = { [weak self] (thumbstick: GameControllerThumbstick, xValue: Float, yValue: Float) in
            guard let self else { return }
            let thumbstickEnabled = self.thumbstickStatus?(thumbstick) ?? true
            guard thumbstickEnabled else { return }

            guard self.canAcceptEvents() else {
                return
            }

            let shouldInvertX = self.axisInversion?(.X) ?? false
            let shouldInvertY = self.axisInversion?(.Y) ?? false
            Task { @MainActor in
                await self.executor.run { core in
                    core.joystickAxis(thumbstick == .right ? .rightX : .X, amount: shouldInvertX ? -xValue : xValue)
                    core.joystickAxis(thumbstick == .right ? .rightY : .Y, amount: shouldInvertY ? -yValue : yValue)
                }
            }
        }
        buttonMenu?.valueChangedHandler = { [weak self] _, _, pressed in
            guard let self = self else { return }
            guard self.canAcceptEvents() else {
                return
            }
            if !pressed {
                Task { @MainActor in
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
