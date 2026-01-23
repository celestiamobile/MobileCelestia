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

class ControlButtonView: UIView, UIContentSizeCategoryAdjusting {
    private enum Constants {
        static let buttonPadding: CGFloat = 8
    }

    private struct Configuration {
        var button: CelestiaControlButton
        var tap: ((CelestiaControlAction) -> Void)?
        var pressStart: ((CelestiaControlAction) -> Void)?
        var pressEnd: ((CelestiaControlAction) -> Void)?
        var toggle: ((CelestiaControlAction) -> Void)?
        var on: Bool = false
    }

    var adjustsFontForContentSizeCategory = true

    private var configuration: Configuration {
        didSet {
            configurationUpdated(configuration)
        }
    }

    private var uiButton: UIButton?

    init(
        button: CelestiaControlButton,
        tap: ((CelestiaControlAction) -> Void)?,
        pressStart: ((CelestiaControlAction) -> Void)?,
        pressEnd: ((CelestiaControlAction) -> Void)?,
        toggle: ((CelestiaControlAction) -> Void)?
    ) {
        configuration = Configuration(button: button, tap: tap, pressStart: pressStart, pressEnd: pressEnd, toggle: toggle)
        super.init(frame: .zero)
        configurationUpdated(configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createButton(_ button: CelestiaControlButton) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: Constants.buttonPadding, leading: Constants.buttonPadding, bottom: Constants.buttonPadding, trailing: Constants.buttonPadding)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(textStyle: .title3)
        switch button {
        case let .pressAndHold(image, _, _):
            configuration.image = image?.withRenderingMode(.alwaysTemplate)
        case let .tap(image, _, _):
            configuration.image = image?.withRenderingMode(.alwaysTemplate)
        case .toggle:
            break
        }
        let uiButton = StandardButton(configuration: configuration)
        uiButton.tintColor = .secondaryLabel
        uiButton.adjustsImageSizeForAccessibilityContentSizeCategory = true
        switch button {
        case let .pressAndHold(_, _, accessibilityLabel):
            uiButton.accessibilityLabel = accessibilityLabel

            uiButton.addTarget(self, action: #selector(pressDidStart(_:)), for: .touchDown)
            uiButton.addTarget(self, action: #selector(pressDidEnd(_:)), for: .touchUpInside)
            uiButton.addTarget(self, action: #selector(pressDidEnd(_:)), for: .touchUpOutside)
            uiButton.addTarget(self, action: #selector(pressDidEnd(_:)), for: .touchCancel)
        case let .tap(_, _, accessibilityLabel):
            uiButton.accessibilityLabel = accessibilityLabel

            uiButton.addTarget(self, action: #selector(didTap(_:)), for: .touchUpInside)
        case .toggle:
            uiButton.addTarget(self, action: #selector(didToggle(_:)), for: .touchUpInside)
        }
        return uiButton
    }

    private func configurationUpdated(_ configuration: Configuration) {
        let button: UIButton
        if let uiButton {
            button = uiButton
        } else {
            button = createButton(configuration.button)
            uiButton = button
            button.translatesAutoresizingMaskIntoConstraints = false
            addSubview(button)
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: leadingAnchor),
                button.trailingAnchor.constraint(equalTo: trailingAnchor),
                button.topAnchor.constraint(equalTo: topAnchor),
                button.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
        switch configuration.button {
        case .toggle(_, let offImage, _, let offAccessibilityValue, let onImage, _, let onAccessibilityValue):
            button.configuration?.image = (configuration.on ? onImage : offImage)?.withRenderingMode(.alwaysTemplate)
            button.accessibilityValue = configuration.on ? offAccessibilityValue : onAccessibilityValue
        default:
            break
        }
    }

    @objc private func didTap(_ sender: UIButton) {
        guard case CelestiaControlButton.tap(_, let action, _) = configuration.button else { return }
        configuration.tap?(action)
    }

    @objc private func pressDidStart(_ sender: UIButton) {
        guard case CelestiaControlButton.pressAndHold(_, let action, _) = configuration.button else { return }
        configuration.pressStart?(action)
    }

    @objc private func pressDidEnd(_ sender: UIButton) {
        guard case CelestiaControlButton.pressAndHold(_, let action, _) = configuration.button else { return }
        configuration.pressEnd?(action)
    }

    @objc private func didToggle(_ sender: UIButton) {
        guard case CelestiaControlButton.toggle(_, _, let offAction, _, _, let onAction, _) = configuration.button else { return }
        let on = configuration.on
        configuration.on = !on
        configuration.toggle?(configuration.on ? onAction : offAction)
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

        maximumContentSizeCategory = .extraExtraExtraLarge

        let buttons = items.map { item in
            return ControlButtonView(button: item) { [weak self] action in
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

        let effect: UIVisualEffect
        if #available(iOS 26, *) {
            let glassEffect = UIGlassEffect(style: .regular)
            glassEffect.isInteractive = true
            effect = glassEffect
        } else {
            effect = UIBlurEffect(style: .regular)
        }
        let visualBackground = UIVisualEffectView(effect: effect)
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

        visualBackground.contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: visualBackground.contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: visualBackground.contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: visualBackground.contentView.topAnchor, constant: Constants.controlViewMarginVertical),
            stackView.bottomAnchor.constraint(equalTo: visualBackground.contentView.bottomAnchor, constant: -Constants.controlViewMarginVertical)
        ])

        if #available(iOS 26, *) {
            visualBackground.cornerConfiguration = .corners(radius: .fixed(Constants.cornerRadius))
        } else {
            clipsToBounds = true
            layer.cornerCurve = .continuous
            layer.cornerRadius = Constants.cornerRadius
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
