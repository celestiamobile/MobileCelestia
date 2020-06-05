//
//  CelestiaControlView.swift
//  MobileCelestia
//
//  Created by 李林峰 on 2020/4/14.
//  Copyright © 2020 李林峰. All rights reserved.
//

import UIKit

enum CelestiaControlAction {
    case zoomIn
    case zoomOut
    case showMenu
    case switchToObject
    case switchToCamera
    case info
}

enum CelestiaControlButton {
    case toggle(offImage: UIImage, offAction: CelestiaControlAction, onImage: UIImage, onAction: CelestiaControlAction)
    case pressAndHold(image: UIImage, action: CelestiaControlAction)
    case tap(image: UIImage, action: CelestiaControlAction)
}

protocol CelestiaControlViewDelegate: class {
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, pressDidStartWith action: CelestiaControlAction)
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, pressDidEndWith action: CelestiaControlAction)
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, didTapWith action: CelestiaControlAction)
    func celestiaControlView(_ celestiaControlView: CelestiaControlView, didToggleTo action: CelestiaControlAction)
}

final class CelestiaControlView: UIView {
    private class Button: UIButton {
        override var isHighlighted: Bool {
            get { return super.isHighlighted }
            set { alpha = newValue ? 0.3 : 1 }
        }

        init() {
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private let buttonProperties: [CelestiaControlButton]

    weak var delegate: CelestiaControlViewDelegate?

    init(items: [CelestiaControlButton]) {
        buttonProperties = items

        super.init(frame: .zero)

        backgroundColor = .clear
        clipsToBounds = true
        layer.cornerRadius = 8

        let buttons = buttonProperties.enumerated().map { (arg) -> UIButton in
            let (offset, element) = arg
            let button = Button()
            button.imageView?.contentMode = .center
            button.tintColor = .darkSecondaryLabel
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 44),
                button.widthAnchor.constraint(equalToConstant: 44)
            ])
            switch element {
            case .pressAndHold(let image, _):
                button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
                button.addTarget(self, action: #selector(pressDidStart(_:)), for: .touchDown)
                button.addTarget(self, action: #selector(pressDidEnd(_:)), for: .touchUpInside)
                button.addTarget(self, action: #selector(pressDidEnd(_:)), for: .touchUpOutside)
                button.addTarget(self, action: #selector(pressDidEnd(_:)), for: .touchCancel)
            case .tap(let image, _):
                button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
                button.addTarget(self, action: #selector(didTap(_:)), for: .touchUpInside)
            case .toggle(let offImage, _, let onImage, _):
                button.setImage(offImage.withRenderingMode(.alwaysTemplate), for: .normal)
                button.setImage(onImage.withRenderingMode(.alwaysTemplate), for: .selected)
                button.addTarget(self, action: #selector(didToggle(_:)), for: .touchUpInside)
            }
            button.tag = offset
            return button
        }

        let visualBackground = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
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

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    @objc private func didTap(_ sender: UIButton) {
        let property = buttonProperties[sender.tag]
        guard case CelestiaControlButton.tap(_, let action) = property else { return }
        delegate?.celestiaControlView(self, didTapWith: action)
    }

    @objc private func pressDidStart(_ sender: UIButton) {
        let property = buttonProperties[sender.tag]
        guard case CelestiaControlButton.pressAndHold(_, let action) = property else { return }
        delegate?.celestiaControlView(self, pressDidStartWith: action)
    }

    @objc private func pressDidEnd(_ sender: UIButton) {
        let property = buttonProperties[sender.tag]
        guard case CelestiaControlButton.pressAndHold(_, let action) = property else { return }
        delegate?.celestiaControlView(self, pressDidEndWith: action)
    }

    @objc private func didToggle(_ sender: UIButton) {
        let property = buttonProperties[sender.tag]
        guard case CelestiaControlButton.toggle(_, let offAction, _, let onAction) = property else { return }

        sender.isSelected = !sender.isSelected

        delegate?.celestiaControlView(self, didToggleTo: sender.isSelected ? onAction : offAction)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
