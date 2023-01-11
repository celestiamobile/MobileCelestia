//
// CelestiaControlView.swift
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import UIKit

enum CelestiaControlAction {
    case zoomIn
    case zoomOut
    case showMenu
    case switchToObject
    case switchToCamera
    case info
    case hide
    case show
}

enum CelestiaControlButton {
    case toggle(offImage: UIImage?, offAction: CelestiaControlAction, onImage: UIImage?, onAction: CelestiaControlAction)
    case pressAndHold(image: UIImage?, action: CelestiaControlAction)
    case tap(image: UIImage?, action: CelestiaControlAction)
}

@MainActor
protocol CelestiaControlViewDelegate: AnyObject {
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, pressDidStartWith action: CelestiaControlAction)
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, pressDidEndWith action: CelestiaControlAction)
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, didTapWith action: CelestiaControlAction)
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, didToggleTo action: CelestiaControlAction)
}

class ControlButton: ImageButtonView<ControlButton.Configuration> {
    struct Configuration: ImageProvider {
        var button: CelestiaControlButton
        var tap: ((CelestiaControlAction) -> Void)?
        var pressStart: ((CelestiaControlAction) -> Void)?
        var pressEnd: ((CelestiaControlAction) -> Void)?
        var toggle: ((CelestiaControlAction) -> Void)?

        var shouldScaleOnMacCatalyst: Bool { return false }

        func provideImage(selected: Bool) -> UIImage? {
            switch button {
            case .pressAndHold(let image, _):
                return image?.withRenderingMode(.alwaysTemplate)
            case .tap(let image, _):
                return image?.withRenderingMode(.alwaysTemplate)
            case .toggle(let offImage, _, let onImage, _):
                return (selected ? onImage : offImage)?.withRenderingMode(.alwaysTemplate)
            }
        }
    }

    init(button: CelestiaControlButton, tap: ((CelestiaControlAction) -> Void)?, pressStart: ((CelestiaControlAction) -> Void)?, pressEnd: ((CelestiaControlAction) -> Void)?, toggle: ((CelestiaControlAction) -> Void)?) {
        super.init(buttonBuilder: {
            let button = StandardButton()
            button.imageView?.contentMode = .scaleAspectFit
            button.contentHorizontalAlignment = .fill
            button.contentVerticalAlignment = .fill
            button.tintColor = .darkSecondaryLabel
            return button
        }(), boundingBoxSize: CGSize(width: 40, height: 40), configurationBuilder: Configuration(button: button, tap: tap, pressStart: pressStart, pressEnd: pressEnd, toggle: toggle))
    }

    override func configurationUpdated(_ configuration: Configuration, button: UIButton) {
        super.configurationUpdated(configuration, button: button)
        button.removeTarget(self, action: nil, for: .allEvents)
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
    }

    @objc private func didTap(_ sender: UIButton) {
        guard case CelestiaControlButton.tap(_, let action) = configuration.configuration.button else { return }
        configuration.configuration.tap?(action)
    }

    @objc private func pressDidStart(_ sender: UIButton) {
        guard case CelestiaControlButton.pressAndHold(_, let action) = configuration.configuration.button else { return }
        configuration.configuration.pressStart?(action)
    }

    @objc private func pressDidEnd(_ sender: UIButton) {
        guard case CelestiaControlButton.pressAndHold(_, let action) = configuration.configuration.button else { return }
        configuration.configuration.pressEnd?(action)
    }

    @objc private func didToggle(_ sender: UIButton) {
        guard case CelestiaControlButton.toggle(_, let offAction, _, let onAction) = configuration.configuration.button else { return }
        sender.isSelected = !sender.isSelected
        configuration.configuration.toggle?(sender.isSelected ? onAction : offAction)
    }
}

final class CelestiaControlView: UIView {
    private enum Constants {
        static let controlViewMargin: CGFloat = 8
        static let controlViewSpacing: CGFloat = 6
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

        let style: UIBlurEffect.Style
        if #available(iOS 13.0, *) {
            style = .regular
        } else {
            style = .dark
        }
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
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.controlViewMargin),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.controlViewMargin),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.controlViewMargin),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.controlViewMargin)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
