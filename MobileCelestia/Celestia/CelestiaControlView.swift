// CelestiaControlView.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaUI
import UIKit

#if !targetEnvironment(macCatalyst)
enum CelestiaControlAction {
    case zoomIn
    case zoomOut
    case showMenu
    case switchToObject
    case switchToCamera
    case info
    case hide
    case show
    case search
    case go
}

enum CelestiaControlButton {
    case toggle(accessibilityLabel: String, offImage: UIImage?, offAction: CelestiaControlAction, offAccessibilityValue: String, onImage: UIImage?, onAction: CelestiaControlAction, onAccessibilityValue: String)
    case pressAndHold(image: UIImage?, action: CelestiaControlAction, accessibilityLabel: String)
    case tap(image: UIImage?, action: CelestiaControlAction, accessibilityLabel: String)
}

@MainActor
protocol CelestiaControlViewDelegate: AnyObject {
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, pressDidStartWith action: CelestiaControlAction)
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, pressDidEndWith action: CelestiaControlAction)
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, didTapWith action: CelestiaControlAction)
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, didToggleTo action: CelestiaControlAction)
}

class ControlButton: ImageButtonView<ControlButton.Configuration> {
    private enum Constants {
        static let buttonSize: CGFloat = 48
        static let buttonPadding: CGFloat = 8
    }

    struct Configuration: ImageProvider {
        var button: CelestiaControlButton
        var tap: ((CelestiaControlAction) -> Void)?
        var pressStart: ((CelestiaControlAction) -> Void)?
        var pressEnd: ((CelestiaControlAction) -> Void)?
        var toggle: ((CelestiaControlAction) -> Void)?
        var on: Bool = false

        var shouldScaleOnMacCatalyst: Bool { return false }

        func provideImage() -> UIImage? {
            switch button {
            case .pressAndHold(let image, _, _):
                return image?.withRenderingMode(.alwaysTemplate)
            case .tap(let image, _, _):
                return image?.withRenderingMode(.alwaysTemplate)
            case .toggle(_, let offImage, _, _, _, _, _):
                return offImage?.withRenderingMode(.alwaysTemplate)
            }
        }
    }

    private var areActionsSetUp = false

    init(button: CelestiaControlButton, tap: ((CelestiaControlAction) -> Void)?, pressStart: ((CelestiaControlAction) -> Void)?, pressEnd: ((CelestiaControlAction) -> Void)?, toggle: ((CelestiaControlAction) -> Void)?) {
        super.init(buttonBuilder: {
            let uiButton = StandardButton()
            uiButton.imageView?.contentMode = .scaleAspectFit
            uiButton.contentHorizontalAlignment = .fill
            uiButton.contentVerticalAlignment = .fill
            uiButton.tintColor = .secondaryLabel
            uiButton.imageEdgeInsets = UIEdgeInsets(top: Constants.buttonPadding, left: Constants.buttonPadding, bottom: Constants.buttonPadding, right: Constants.buttonPadding)
            switch button {
            case .pressAndHold(_, _, let accessibilityLabel):
                uiButton.accessibilityLabel = accessibilityLabel
            case .tap(_, _, let accessibilityLabel):
                uiButton.accessibilityLabel = accessibilityLabel
            case .toggle(let accessibilityLabel, _, _, _, _, _, _):
                uiButton.accessibilityLabel = accessibilityLabel
            }
            return uiButton
        }(), boundingBoxSize: CGSize(width: Constants.buttonSize, height: Constants.buttonSize), configurationBuilder: Configuration(button: button, tap: tap, pressStart: pressStart, pressEnd: pressEnd, toggle: toggle))
    }

    override func configurationUpdated(_ configuration: Configuration, button: UIButton) {
        super.configurationUpdated(configuration, button: button)
        if !areActionsSetUp {
            switch configuration.button {
            case .pressAndHold:
                button.addTarget(self, action: #selector(pressDidStart(_:)), for: .touchDown)
                button.addTarget(self, action: #selector(pressDidEnd(_:)), for: .touchUpInside)
                button.addTarget(self, action: #selector(pressDidEnd(_:)), for: .touchUpOutside)
                button.addTarget(self, action: #selector(pressDidEnd(_:)), for: .touchCancel)
            case .tap:
                button.addTarget(self, action: #selector(didTap(_:)), for: .touchUpInside)
            case .toggle:
                button.addTarget(self, action: #selector(didToggle(_:)), for: .touchUpInside)
            }
            areActionsSetUp = true
        }
        switch configuration.button {
        case .toggle(_, let offImage, _, let offAccessibilityValue, let onImage, _, let onAccessibilityValue):
            button.setImage(configuration.on ? onImage : offImage, for: .normal)
            button.accessibilityValue = configuration.on ? offAccessibilityValue : onAccessibilityValue
            button.addTarget(self, action: #selector(didToggle(_:)), for: .touchUpInside)
        default:
            break
        }
    }

    @objc private func didTap(_ sender: UIButton) {
        guard case CelestiaControlButton.tap(_, let action, _) = configuration.configuration.button else { return }
        configuration.configuration.tap?(action)
    }

    @objc private func pressDidStart(_ sender: UIButton) {
        guard case CelestiaControlButton.pressAndHold(_, let action, _) = configuration.configuration.button else { return }
        configuration.configuration.pressStart?(action)
    }

    @objc private func pressDidEnd(_ sender: UIButton) {
        guard case CelestiaControlButton.pressAndHold(_, let action, _) = configuration.configuration.button else { return }
        configuration.configuration.pressEnd?(action)
    }

    @objc private func didToggle(_ sender: UIButton) {
        guard case CelestiaControlButton.toggle(_, _, let offAction, _, _, let onAction, _) = configuration.configuration.button else { return }
        configuration.configuration.on = !configuration.configuration.on
        configuration.configuration.toggle?(configuration.configuration.on ? onAction : offAction)
    }
}

final class CelestiaControlView: UIView {
    private enum Constants {
        static let controlViewMarginVertical: CGFloat = 4
        static let controlViewSpacing: CGFloat = 0
        static let cornerRadius: CGFloat = 8
    }

    private let buttonProperties: [CelestiaControlButton]

    weak var delegate: CelestiaControlViewDelegate?

    init(items: [CelestiaControlButton]) {
        buttonProperties = items

        super.init(frame: .zero)

        if #available(iOS 15, *) {
            maximumContentSizeCategory = .extraExtraExtraLarge
        }

        backgroundColor = .clear
        clipsToBounds = true
        layer.cornerCurve = .continuous
        layer.cornerRadius = Constants.cornerRadius

        let buttons = items.map { item in
            return ControlButton(button: item) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.celestiaControlView(self, didTapWith: action)
            } pressStart: {  [weak self] action in
                guard let self = self else { return }
                self.delegate?.celestiaControlView(self, pressDidStartWith: action)
            } pressEnd: {  [weak self] action in
                guard let self = self else { return }
                self.delegate?.celestiaControlView(self, pressDidEndWith: action)
            } toggle: { [weak self] action in
                guard let self = self else { return }
                self.delegate?.celestiaControlView(self, didToggleTo: action)
            }
        }

        let style: UIBlurEffect.Style = .regular
        let visualBackground = UIVisualEffectView(effect: UIBlurEffect(style: style))
        visualBackground.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualBackground)
        NSLayoutConstraint.activate([
            visualBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualBackground.topAnchor.constraint(equalTo: topAnchor),
            visualBackground.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Constants.controlViewSpacing

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.controlViewMarginVertical),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.controlViewMarginVertical)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
